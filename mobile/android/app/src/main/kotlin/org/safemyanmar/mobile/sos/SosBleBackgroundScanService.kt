package org.safemyanmar.mobile.sos

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import org.safemyanmar.mobile.MainActivity

class SosBleBackgroundScanService : Service() {
    private lateinit var store: SosBleBackgroundEventStore
    private var scanner: BluetoothLeScanner? = null
    private var scanning = false

    override fun onCreate() {
        super.onCreate()
        store = SosBleBackgroundEventStore(applicationContext)
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            store.setEnabled(false)
            stopScanning()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelfResult(startId)
            return START_NOT_STICKY
        }
        if (!store.isEnabled() && intent == null) {
            stopSelfResult(startId)
            return START_NOT_STICKY
        }
        store.setEnabled(true)
        try {
            val notification = notification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_CONNECTED_DEVICE,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            startScanning()
        } catch (error: Throwable) {
            android.util.Log.e(TAG, "Unable to start background SOS scanning", error)
            store.setEnabled(false)
            stopSelfResult(startId)
        }
        return START_STICKY
    }

    override fun onDestroy() {
        stopScanning()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startScanning() {
        if (scanning) return
        val adapter = (getSystemService(BLUETOOTH_SERVICE) as BluetoothManager).adapter
            ?: throw IllegalStateException("Bluetooth scanning is unavailable.")
        if (!adapter.isEnabled) throw IllegalStateException("Bluetooth is disabled.")
        val currentScanner = adapter.bluetoothLeScanner
            ?: throw IllegalStateException("Bluetooth scanning is unavailable.")
        currentScanner.startScan(
            null,
            ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_POWER).build(),
            scanCallback,
        )
        scanner = currentScanner
        scanning = true
        android.util.Log.i(TAG, "Background BLE SOS scanning started")
    }

    private fun stopScanning() {
        if (!scanning) return
        try {
            scanner?.stopScan(scanCallback)
        } catch (_: SecurityException) {
            // Permission revocation should not prevent service shutdown.
        }
        scanner = null
        scanning = false
    }

    private val scanCallback = object : ScanCallback() {
        override fun onScanResult(callbackType: Int, result: ScanResult) {
            val payload = result.scanRecord?.getManufacturerSpecificData(SosBleBridge.MANUFACTURER_ID)
                ?: return
            val event = try {
                store.add(payload, result.rssi)
            } catch (error: Throwable) {
                android.util.Log.w(TAG, "Unable to persist background SOS frame", error)
                null
            } ?: return
            sendBroadcast(
                Intent(ACTION_EVENT).apply {
                    setPackage(packageName)
                    putExtra(EXTRA_PAYLOAD, event.payload)
                    putExtra(EXTRA_RSSI, event.rssi)
                    putExtra(EXTRA_BACKGROUND, true)
                },
            )
            notifyIncoming(event)
        }

        override fun onScanFailed(errorCode: Int) {
            android.util.Log.e(TAG, "Background BLE SOS scanning failed: $errorCode")
            stopScanning()
            store.setEnabled(false)
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    private fun notifyIncoming(event: StoredSosBleEvent) {
        val notificationKey = event.senderToken ?: event.eventId
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_SOS_EVENT_ID, event.eventId)
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            notificationKey.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val manager = getSystemService(NotificationManager::class.java)
        try {
            manager.notify(
                notificationKey.hashCode(),
                NotificationCompat.Builder(this, INCOMING_CHANNEL_ID)
                    .setSmallIcon(android.R.drawable.ic_dialog_alert)
                    .setContentTitle("Nearby unverified SOS")
                    .setContentText("A nearby device reported an SOS. Tap to view it on the map.")
                    .setContentIntent(pendingIntent)
                    .setAutoCancel(true)
                    .setCategory(NotificationCompat.CATEGORY_ALARM)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .build(),
            )
        } catch (error: SecurityException) {
            android.util.Log.w(TAG, "Notification permission is unavailable", error)
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel(
                SERVICE_CHANNEL_ID,
                "Background SOS receiver",
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
        manager.createNotificationChannel(
            NotificationChannel(
                INCOMING_CHANNEL_ID,
                "Nearby SOS alerts",
                NotificationManager.IMPORTANCE_HIGH,
            ),
        )
    }

    private fun notification(): Notification {
        val stopIntent = Intent(this, SosBleBackgroundScanService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPendingIntent = PendingIntent.getService(
            this,
            STOP_REQUEST_CODE,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, SERVICE_CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Background SOS receiver is active")
            .setContentText("SafeMyanmar is listening for nearby SOS frames.")
            .setOngoing(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Stop",
                stopPendingIntent,
            )
            .build()
    }

    companion object {
        const val ACTION_EVENT = "org.safemyanmar.mobile.sos.BACKGROUND_EVENT"
        const val EXTRA_PAYLOAD = "payload"
        const val EXTRA_RSSI = "rssi"
        const val EXTRA_BACKGROUND = "background"
        private const val ACTION_STOP = "org.safemyanmar.mobile.sos.STOP_BACKGROUND_SCAN"
        private const val SERVICE_CHANNEL_ID = "background_sos_receiver"
        private const val INCOMING_CHANNEL_ID = "nearby_sos_alerts"
        private const val NOTIFICATION_ID = 4403
        private const val STOP_REQUEST_CODE = 4404
        private const val TAG = "SosBleBackgroundScan"

        fun start(context: Context) {
            val intent = Intent(context, SosBleBackgroundScanService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.startService(
                Intent(context, SosBleBackgroundScanService::class.java).apply {
                    action = ACTION_STOP
                },
            )
        }
    }
}
