package org.safemyanmar.mobile.sos

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.ResultReceiver
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
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingBroadcastResult: MethodChannel.Result? = null
    private val handler = Handler(Looper.getMainLooper())
    private var broadcastTimeout: Runnable? = null
    private val scanning = AtomicBoolean(false)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> result.success(
                activity.packageManager.hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE) &&
                    bluetoothAdapter != null,
            )
            "requestPermissions" -> requestPermissions(result)
            "batteryPercent" -> result.success(batteryPercent())
            "startBroadcast" -> {
                val payload = call.argument<ByteArray>("payload")
                if (payload == null || payload.size != 22) {
                    result.error("invalid_payload", "SOS BLE payload must contain 22 bytes.", null)
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
                        SosBleBroadcastService.start(activity, payload, receiver)
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
            "stopBroadcast" -> {
                SosBleBroadcastService.stop(activity)
                result.success(null)
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
        handler.removeCallbacksAndMessages(null)
        stopScan()
        eventSink = null
    }

    private fun completeBroadcast(completion: MethodChannel.Result.() -> Unit) {
        val result = pendingBroadcastResult ?: return
        pendingBroadcastResult = null
        broadcastTimeout?.let(handler::removeCallbacks)
        broadcastTimeout = null
        result.completion()
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        if (pendingPermissionResult != null) {
            result.success(false)
            return
        }
        val missing = requiredPermissions().filter {
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

    private fun requiredPermissions(): List<String> = buildList {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            add(Manifest.permission.BLUETOOTH_SCAN)
            add(Manifest.permission.BLUETOOTH_ADVERTISE)
            add(Manifest.permission.BLUETOOTH_CONNECT)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            add(Manifest.permission.POST_NOTIFICATIONS)
        }
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
        const val MANUFACTURER_ID = 0xffff
        private const val PERMISSION_REQUEST_CODE = 4401
        private const val BROADCAST_START_TIMEOUT_MS = 5_000L
        private const val EXTRA_ERROR_CODE = "error_code"
        private const val TAG = "SosBleBridge"
    }
}
