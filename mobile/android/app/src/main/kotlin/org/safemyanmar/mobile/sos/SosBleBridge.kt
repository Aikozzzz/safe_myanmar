package org.safemyanmar.mobile.sos

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
import android.provider.Settings
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class SosBleBridge(private val activity: Activity) :
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    AutoCloseable {
    private val bluetoothManager =
        activity.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    private val bluetoothAdapter: BluetoothAdapter?
        get() = bluetoothManager.adapter
    private var scanner: BluetoothLeScanner? = null
    private var eventSink: EventChannel.EventSink? = null
    private var notificationEventSink: EventChannel.EventSink? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingBroadcastResult: MethodChannel.Result? = null
    private var pendingStopResult: MethodChannel.Result? = null
    private val handler = Handler(Looper.getMainLooper())
    private val backgroundEventStore = SosBleBackgroundEventStore(activity.applicationContext)
    private var pendingNotificationEventId: String? =
        activity.intent?.getStringExtra(EXTRA_NOTIFICATION_EVENT_ID)
    private var backgroundReceiverRegistered = false
    private var broadcastTimeout: Runnable? = null
    private var stopTimeout: Runnable? = null
    private val scanning = AtomicBoolean(false)

    val notificationEventStreamHandler = object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            notificationEventSink = events
        }

        override fun onCancel(arguments: Any?) {
            notificationEventSink = null
        }
    }

    private val backgroundEventReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val payload = intent?.getByteArrayExtra(SosBleBackgroundScanService.EXTRA_PAYLOAD)
                ?: return
            eventSink?.success(
                mapOf(
                    "data" to payload,
                    "rssi" to if (intent.hasExtra(SosBleBackgroundScanService.EXTRA_RSSI)) {
                        intent.getIntExtra(SosBleBackgroundScanService.EXTRA_RSSI, 0)
                    } else {
                        null
                    },
                    "background" to true,
                ),
            )
        }
    }

    init {
        val filter = IntentFilter(SosBleBackgroundScanService.ACTION_EVENT)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.registerReceiver(
                backgroundEventReceiver,
                filter,
                Context.RECEIVER_NOT_EXPORTED,
            )
        } else {
            @Suppress("DEPRECATION")
            activity.registerReceiver(backgroundEventReceiver, filter)
        }
        backgroundReceiverRegistered = true
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(permissionState()["supported"])
            "getPermissionState" -> result.success(permissionState())
            "openAppSettings" -> result.success(openAppSettings())
            "requestPermissions" -> requestPermissions(
                result,
                receive = call.argument<Boolean>("receive") == true,
                broadcast = call.argument<Boolean>("broadcast") == true,
                background = call.argument<Boolean>("background") == true,
            )
            "batteryPercent" -> result.success(batteryPercent())
            "isBackgroundScanEnabled" -> result.success(backgroundEventStore.isEnabled())
            "startBackgroundScan" -> {
                try {
                    backgroundEventStore.setEnabled(true)
                    SosBleBackgroundScanService.start(activity)
                    result.success(null)
                } catch (error: Throwable) {
                    backgroundEventStore.setEnabled(false)
                    result.error("background_scan_failed", error.message, null)
                }
            }
            "stopBackgroundScan" -> {
                backgroundEventStore.setEnabled(false)
                SosBleBackgroundScanService.stop(activity)
                result.success(null)
            }
            "readBackgroundAdvertisements" -> result.success(
                backgroundEventStore.asFlutterEvents(),
            )
            "getPendingNotificationEventId" -> {
                result.success(pendingNotificationEventId)
                pendingNotificationEventId = null
            }
            "startBroadcast" -> {
                val payload = call.argument<ByteArray>("payload")
                if (payload == null || payload.size != PAYLOAD_SIZE) {
                    result.error("invalid_payload", "SOS BLE payload must contain $PAYLOAD_SIZE bytes.", null)
                } else {
                    val frame = SosBleFrameValidator.validate(payload)
                    if (frame == null) {
                        result.error("invalid_payload", "SOS BLE payload is invalid or expired.", null)
                    } else {
                        try {
                            if (bluetoothAdapter?.isEnabled != true ||
                                bluetoothAdapter?.bluetoothLeAdvertiser == null
                            ) {
                                throw IllegalStateException("Bluetooth advertising is unavailable.")
                            }
                            if (pendingBroadcastResult != null) {
                                result.error("broadcast_in_progress", "BLE advertising is already starting.", null)
                                return
                            }
                            val durationSeconds = call.argument<Int>("duration_seconds")
                                ?.coerceIn(5, MAX_BROADCAST_SECONDS)
                                ?: MAX_BROADCAST_SECONDS
                            val suppressionExpiry = minOf(
                                frame.createdAtMillis + frame.ttlMinutes * MINUTE_MILLIS,
                                System.currentTimeMillis() +
                                    durationSeconds * 1000L + ORIGIN_SUPPRESSION_GRACE_MS,
                            )
                            if (!backgroundEventStore.rememberOriginatedEvent(
                                    frame.eventId,
                                    suppressionExpiry,
                                )
                            ) {
                                result.error(
                                    "origin_tracker_unavailable",
                                    "Unable to register the local BLE event.",
                                    null,
                                )
                                return
                            }
                            pendingBroadcastResult = result
                            val receiver = object : ResultReceiver(handler) {
                                override fun onReceiveResult(resultCode: Int, resultData: Bundle?) {
                                    val errorCode = resultData?.getInt(EXTRA_ERROR_CODE, -1) ?: -1
                                    if (resultCode == SosBleBroadcastService.RESULT_STARTED) {
                                        completeBroadcast { success(null) }
                                    } else {
                                        completeBroadcast {
                                            error(
                                                "broadcast_failed",
                                                "BLE advertising failed: $errorCode",
                                                errorCode,
                                            )
                                        }
                                    }
                                }
                            }
                            SosBleBroadcastService.start(
                                activity,
                                payload,
                                receiver,
                                durationSeconds * 1000L,
                            )
                            broadcastTimeout = Runnable {
                                completeBroadcast {
                                    error("broadcast_timeout", "BLE advertising did not start in time.", null)
                                }
                            }
                            handler.postDelayed(broadcastTimeout!!, BROADCAST_START_TIMEOUT_MS)
                        } catch (exception: SecurityException) {
                            completeBroadcast {
                                error("permission_denied", exception.message, null)
                            }
                        } catch (exception: IllegalStateException) {
                            completeBroadcast {
                                error("unavailable", exception.message, null)
                            }
                        } catch (exception: Throwable) {
                            completeBroadcast {
                                error("broadcast_failed", exception.message, null)
                            }
                        }
                    }
                }
            }
            "stopBroadcast" -> {
                if (pendingStopResult != null) {
                    result.error("stop_in_progress", "BLE advertising is already stopping.", null)
                    return
                }
                completeBroadcast {
                    error("broadcast_stopped", "BLE advertising was stopped before it started.", null)
                }
                pendingStopResult = result
                val receiver = object : ResultReceiver(handler) {
                    override fun onReceiveResult(resultCode: Int, resultData: Bundle?) {
                        if (resultCode == SosBleBroadcastService.RESULT_STOPPED) {
                            completeStop { success(null) }
                        } else {
                            completeStop {
                                error("broadcast_stop_failed", "BLE advertising could not be stopped.", null)
                            }
                        }
                    }
                }
                SosBleBroadcastService.stop(activity, receiver)
                stopTimeout = Runnable {
                    completeStop {
                        error("broadcast_stop_timeout", "BLE advertising did not stop in time.", null)
                    }
                }
                handler.postDelayed(stopTimeout!!, STOP_TIMEOUT_MS)
            }
            "startScan" -> startScan(result)
            "stopScan" -> {
                stopScan()
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopScan()
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val granted = permissions.indices.all { index ->
            grantResults.getOrNull(index) == PackageManager.PERMISSION_GRANTED
        }
        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
        return true
    }

    override fun close() {
        pendingPermissionResult?.success(false)
        pendingPermissionResult = null
        completeBroadcast { error("bridge_closed", "BLE bridge was closed.", null) }
        completeStop { error("bridge_closed", "BLE bridge was closed.", null) }
        handler.removeCallbacksAndMessages(null)
        stopScan()
        if (backgroundReceiverRegistered) {
            try {
                activity.unregisterReceiver(backgroundEventReceiver)
            } catch (_: IllegalArgumentException) {
                // The activity may already have unregistered the receiver.
            }
            backgroundReceiverRegistered = false
        }
        eventSink = null
        notificationEventSink = null
    }

    fun onNewIntent(intent: Intent) {
        val eventId = intent.getStringExtra(EXTRA_NOTIFICATION_EVENT_ID) ?: return
        pendingNotificationEventId = eventId
        notificationEventSink?.success(eventId)
    }

    private fun completeBroadcast(completion: MethodChannel.Result.() -> Unit) {
        val result = pendingBroadcastResult ?: return
        pendingBroadcastResult = null
        broadcastTimeout?.let(handler::removeCallbacks)
        broadcastTimeout = null
        result.completion()
    }

    private fun completeStop(completion: MethodChannel.Result.() -> Unit) {
        val result = pendingStopResult ?: return
        pendingStopResult = null
        stopTimeout?.let(handler::removeCallbacks)
        stopTimeout = null
        result.completion()
    }

    private fun requestPermissions(
        result: MethodChannel.Result,
        receive: Boolean,
        broadcast: Boolean,
        background: Boolean,
    ) {
        if (pendingPermissionResult != null) {
            result.success(false)
            return
        }
        val missing = requiredPermissions(receive, broadcast, background).filter {
            Build.VERSION.SDK_INT < 23 ||
                activity.checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            result.success(true)
            return
        }
        pendingPermissionResult = result
        activity.requestPermissions(missing.toTypedArray(), PERMISSION_REQUEST_CODE)
    }

    private fun requiredPermissions(
        receive: Boolean,
        broadcast: Boolean,
        background: Boolean,
    ): List<String> = buildList {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (receive) add(Manifest.permission.BLUETOOTH_SCAN)
            if (receive || broadcast) add(Manifest.permission.BLUETOOTH_CONNECT)
            if (broadcast) add(Manifest.permission.BLUETOOTH_ADVERTISE)
        } else if (receive) {
            add(Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        if (background && Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            add(Manifest.permission.POST_NOTIFICATIONS)
        }
    }

    private fun permissionState(): Map<String, Any> {
        val supported = activity.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE) &&
            bluetoothAdapter != null
        val bluetoothEnabled = try {
            bluetoothAdapter?.isEnabled == true
        } catch (_: SecurityException) {
            false
        }
        val scanGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            hasPermission(Manifest.permission.BLUETOOTH_SCAN) &&
                hasPermission(Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            hasPermission(Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        val advertiseGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            hasPermission(Manifest.permission.BLUETOOTH_ADVERTISE) &&
                hasPermission(Manifest.permission.BLUETOOTH_CONNECT)
        } else {
            true
        }
        val notificationGranted = Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            hasPermission(Manifest.permission.POST_NOTIFICATIONS)
        return mapOf(
            "supported" to supported,
            "bluetooth_enabled" to bluetoothEnabled,
            "scan_granted" to scanGranted,
            "advertise_granted" to advertiseGranted,
            "notification_granted" to notificationGranted,
        )
    }

    private fun hasPermission(permission: String): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            activity.checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun openAppSettings(): Boolean = try {
        activity.startActivity(
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:${activity.packageName}"),
            ),
        )
        true
    } catch (_: Throwable) {
        false
    }

    private fun batteryPercent(): Int? {
        val battery = activity.getSystemService(Context.BATTERY_SERVICE) as android.os.BatteryManager
        val value = battery.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY)
        return value.takeIf { it in 0..100 }
    }

    private fun startScan(result: MethodChannel.Result) {
        if (scanning.get()) {
            result.success(null)
            return
        }
        try {
            val currentScanner = bluetoothAdapter?.bluetoothLeScanner
                ?: throw IllegalStateException("Bluetooth scanning is unavailable.")
            scanner = currentScanner
            val settings = android.bluetooth.le.ScanSettings.Builder()
                .setScanMode(android.bluetooth.le.ScanSettings.SCAN_MODE_LOW_LATENCY)
                .build()
            currentScanner.startScan(null, settings, scanCallback)
            scanning.set(true)
            android.util.Log.i(TAG, "BLE SOS scanning started")
            result.success(null)
        } catch (error: SecurityException) {
            result.error("permission_denied", error.message, null)
        } catch (error: IllegalStateException) {
            result.error("unavailable", error.message, null)
        }
    }

    private fun stopScan() {
        if (!scanning.getAndSet(false)) return
        try {
            scanner?.stopScan(scanCallback)
        } catch (_: SecurityException) {
            // The permission may have been revoked while scanning.
        }
        scanner = null
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val payload = result.scanRecord?.getManufacturerSpecificData(MANUFACTURER_ID)
                ?: return
            val eventId = SosBleFrameValidator.eventId(payload)
            if (eventId != null && backgroundEventStore.isOriginatedEvent(eventId)) return
            android.util.Log.i(TAG, "BLE SOS advertisement received")
            eventSink?.success(mapOf("data" to payload, "rssi" to result.rssi))
        }

        override fun onScanFailed(errorCode: Int) {
            android.util.Log.e(TAG, "BLE SOS scanning failed: $errorCode")
            eventSink?.error("scan_failed", "Bluetooth scan failed: $errorCode", null)
            scanning.set(false)
        }
    }

    companion object {
        const val CHANNEL_NAME = "org.safemyanmar.mobile/sos_ble"
        const val EVENT_CHANNEL_NAME = "org.safemyanmar.mobile/sos_ble_events"
        const val NOTIFICATION_EVENT_CHANNEL_NAME =
            "org.safemyanmar.mobile/sos_ble_notification_events"
        const val MANUFACTURER_ID = 0xffff
        const val EXTRA_NOTIFICATION_EVENT_ID = "sos_event_id"
        private const val PAYLOAD_SIZE = 26
        private const val PERMISSION_REQUEST_CODE = 4401
        private const val BROADCAST_START_TIMEOUT_MS = 5_000L
        private const val STOP_TIMEOUT_MS = 5_000L
        private const val MAX_BROADCAST_SECONDS = 10 * 60
        private const val MINUTE_MILLIS = 60_000L
        private const val ORIGIN_SUPPRESSION_GRACE_MS = 15_000L
        private const val EXTRA_ERROR_CODE = "error_code"
        private const val TAG = "SosBleBridge"
    }
}
