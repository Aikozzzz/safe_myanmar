package org.safemyanmar.mobile.sos

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.bluetooth.BluetoothAdapter
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.ResultReceiver
import org.safemyanmar.mobile.R
import java.util.Locale
import androidx.core.app.NotificationCompat
import org.safemyanmar.mobile.MainActivity

class SosBleBroadcastService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private var advertiser: android.bluetooth.le.BluetoothLeAdvertiser? = null
    private var callback: AdvertiseCallback? = null
    private var startResultReceiver: ResultReceiver? = null
    private var stopResultReceiver: ResultReceiver? = null
    private var activeStartId: Int? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopResultReceiver = parcelableResultReceiver(intent)
            stopBroadcast(startId)
            return START_NOT_STICKY
        }
        val payload = intent?.getByteArrayExtra(EXTRA_PAYLOAD)
            ?: return START_NOT_STICKY.also { stopSelfResult(startId) }
        val durationMs = intent.getLongExtra(
            EXTRA_DURATION_MS,
            BROADCAST_DURATION_MS,
        ).coerceIn(5_000L, BROADCAST_DURATION_MS)
        val languageCode = intent.getStringExtra(EXTRA_LANGUAGE) ?: "en"
        startResultReceiver = parcelableResultReceiver(intent)
        try {
            createNotificationChannel(languageCode)
            val notification = notification(languageCode)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            startBroadcast(payload, startId)
            handler.removeCallbacksAndMessages(null)
            handler.postDelayed({
                if (activeStartId == startId) stopBroadcast(startId)
            }, durationMs)
        } catch (error: Throwable) {
            android.util.Log.e(TAG, "Unable to start BLE SOS advertising", error)
            startResultReceiver?.send(
                RESULT_FAILED,
                Bundle().apply { putInt(EXTRA_ERROR_CODE, -1) },
            )
            startResultReceiver = null
            stopBroadcast(startId)
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        stopAdvertising()
        startResultReceiver?.send(
            RESULT_FAILED,
            Bundle().apply { putInt(EXTRA_ERROR_CODE, ERROR_STOPPED_BEFORE_START) },
        )
        startResultReceiver = null
        stopResultReceiver?.send(RESULT_STOPPED, null)
        stopResultReceiver = null
        activeStartId = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startBroadcast(payload: ByteArray, startId: Int) {
        val adapter = (getSystemService(BLUETOOTH_SERVICE) as android.bluetooth.BluetoothManager).adapter
            ?: throw IllegalStateException("Bluetooth advertising is unavailable.")
        if (!adapter.isEnabled) throw IllegalStateException("Bluetooth is disabled.")
        val currentAdvertiser = adapter.bluetoothLeAdvertiser
            ?: throw IllegalStateException("Bluetooth advertising is unavailable.")
        // A restart should replace only the advertiser, not terminate this service.
        stopAdvertising()
        activeStartId = startId
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(false)
            .setTimeout(0)
            .build()
        val data = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .addManufacturerData(SosBleBridge.MANUFACTURER_ID, payload)
            .build()
        val advertiseCallback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
                android.util.Log.i(TAG, "BLE SOS advertising started")
                startResultReceiver?.send(RESULT_STARTED, null)
                startResultReceiver = null
            }

            override fun onStartFailure(errorCode: Int) {
                android.util.Log.e(TAG, "BLE SOS advertising failed: $errorCode")
                startResultReceiver?.send(
                    RESULT_FAILED,
                    Bundle().apply { putInt(EXTRA_ERROR_CODE, errorCode) },
                )
                startResultReceiver = null
                stopBroadcast(activeStartId)
            }
        }
        advertiser = currentAdvertiser
        callback = advertiseCallback
        currentAdvertiser.startAdvertising(settings, data, advertiseCallback)
    }

    private fun stopBroadcast(stopSelfId: Int?) {
        handler.removeCallbacksAndMessages(null)
        val hadBroadcastState = activeStartId != null || advertiser != null || callback != null
        stopAdvertising()
        startResultReceiver?.send(
            RESULT_FAILED,
            Bundle().apply { putInt(EXTRA_ERROR_CODE, ERROR_STOPPED_BEFORE_START) },
        )
        startResultReceiver = null
        stopResultReceiver?.send(RESULT_STOPPED, null)
        stopResultReceiver = null
        activeStartId = null
        if (hadBroadcastState) {
            android.util.Log.i(TAG, "BLE SOS advertising stopped")
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelfId?.let { stopSelfResult(it) }
    }

    private fun stopAdvertising() {
        val currentAdvertiser = advertiser
        val currentCallback = callback
        if (currentAdvertiser != null && currentCallback != null) {
            try {
                currentAdvertiser.stopAdvertising(currentCallback)
            } catch (_: SecurityException) {
                // The permission may have been revoked while advertising.
            }
        }
        advertiser = null
        callback = null
    }

    private fun parcelableResultReceiver(intent: Intent): ResultReceiver? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(EXTRA_RESULT_RECEIVER, ResultReceiver::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(EXTRA_RESULT_RECEIVER)
        }
    }

    private fun createNotificationChannel(languageCode: String) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        val localized = localizedResources(languageCode)
        manager.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID,
                localized.getString(R.string.nearby_sos_sharing_channel),
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
    }

    private fun notification(languageCode: String): Notification {
        val localized = localizedResources(languageCode)
        val stopIntent = Intent(this, SosBleBroadcastService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            1,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(localized.getString(R.string.nearby_sos_sharing_title))
            .setContentText(localized.getString(R.string.nearby_sos_sharing_body))
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                localized.getString(R.string.stop),
                stopPendingIntent,
            )
            .build()
    }

    private fun localizedResources(languageCode: String) =
        createConfigurationContext(
            Configuration(resources.configuration).apply {
                setLocale(
                    Locale.forLanguageTag(
                        if (languageCode == "my") "my" else "en",
                    ),
                )
            },
        ).resources

    companion object {
        private const val ACTION_START = "org.safemyanmar.mobile.sos.START_BROADCAST"
        private const val ACTION_STOP = "org.safemyanmar.mobile.sos.STOP_BROADCAST"
        private const val EXTRA_PAYLOAD = "payload"
        private const val EXTRA_DURATION_MS = "duration_ms"
        private const val EXTRA_LANGUAGE = "language"
        private const val CHANNEL_ID = "nearby_sos_sharing"
        private const val NOTIFICATION_ID = 4402
        private const val BROADCAST_DURATION_MS = 10 * 60 * 1000L
        private const val EXTRA_RESULT_RECEIVER = "result_receiver"
        private const val EXTRA_ERROR_CODE = "error_code"
        private const val TAG = "SosBleBroadcastService"
        const val RESULT_STARTED = 1
        const val RESULT_FAILED = 2
        const val RESULT_STOPPED = 3
        private const val ERROR_STOPPED_BEFORE_START = -2

        fun start(
            context: Context,
            payload: ByteArray,
            resultReceiver: ResultReceiver,
            durationMs: Long = BROADCAST_DURATION_MS,
            languageCode: String = "en",
        ) {
            val intent = Intent(context, SosBleBroadcastService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_PAYLOAD, payload)
                putExtra(EXTRA_RESULT_RECEIVER, resultReceiver)
                putExtra(EXTRA_DURATION_MS, durationMs)
                putExtra(EXTRA_LANGUAGE, languageCode)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            stop(context, null)
        }

        fun stop(context: Context, resultReceiver: ResultReceiver?) {
            context.startService(
                Intent(context, SosBleBroadcastService::class.java).apply {
                    action = ACTION_STOP
                    putExtra(EXTRA_RESULT_RECEIVER, resultReceiver)
                },
            )
        }
    }
}
