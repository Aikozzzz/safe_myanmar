package org.safemyanmar.mobile.sos

import android.Manifest
import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class NativeSmsBridge(private val activity: Activity) :
    MethodChannel.MethodCallHandler,
    AutoCloseable {
    private val handler = Handler(Looper.getMainLooper())
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingSend: PendingSend? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestSimPermission" -> requestSimPermission(result)
            "getSimCards" -> getSimCards(result)
            "requestPermission" -> requestPermission(result)
            "send" -> send(call, result)
            else -> result.notImplemented()
        }
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE &&
            requestCode != SIM_PERMISSION_REQUEST_CODE
        ) return false
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
        pendingSend?.complete("failed")
        pendingSend = null
    }

    private fun requestPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            activity.checkSelfPermission(Manifest.permission.SEND_SMS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.success(false)
            return
        }
        pendingPermissionResult = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.SEND_SMS),
            PERMISSION_REQUEST_CODE,
        )
    }

    private fun requestSimPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            activity.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) ==
                PackageManager.PERMISSION_GRANTED
        ) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.success(false)
            return
        }
        pendingPermissionResult = result
        activity.requestPermissions(
            arrayOf(Manifest.permission.READ_PHONE_STATE),
            SIM_PERMISSION_REQUEST_CODE,
        )
    }

    private fun getSimCards(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP_MR1 ||
            activity.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) !=
                PackageManager.PERMISSION_GRANTED
        ) {
            result.success(mapOf("status" to "permission_denied"))
            return
        }
        try {
            val manager = activity.getSystemService(SubscriptionManager::class.java)
            val sims = manager?.activeSubscriptionInfoList.orEmpty()
                .sortedBy { it.simSlotIndex }
                .map { subscription ->
                    val carrier = subscription.carrierName?.toString()?.trim()
                    val display = subscription.displayName?.toString()?.trim()
                    val label = when {
                        !carrier.isNullOrEmpty() -> carrier
                        !display.isNullOrEmpty() -> display
                        else -> "Mobile network"
                    }
                    mapOf(
                        "subscription_id" to subscription.subscriptionId,
                        "slot_index" to subscription.simSlotIndex,
                        "label" to label,
                    )
                }
            result.success(mapOf("status" to "available", "sims" to sims))
        } catch (_: SecurityException) {
            result.success(mapOf("status" to "permission_denied"))
        } catch (_: Throwable) {
            result.success(mapOf("status" to "unavailable"))
        }
    }

    private fun send(call: MethodCall, result: MethodChannel.Result) {
        if (activity.checkSelfPermission(Manifest.permission.SEND_SMS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            result.success(mapOf("status" to "permission_denied"))
            return
        }
        if (pendingSend != null) {
            result.success(mapOf("status" to "failed"))
            return
        }
        val recipients = call.argument<List<String>>("recipients")
        val body = call.argument<String>("body")
        val subscriptionId = call.argument<Int>("subscription_id")
        if (recipients.isNullOrEmpty() || recipients.size > 10 || body.isNullOrBlank() || body.length > 4000) {
            result.success(mapOf("status" to "failed"))
            return
        }
        val smsManager = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1 &&
                subscriptionId != null
            ) {
                val active = activity.getSystemService(
                    SubscriptionManager::class.java,
                )?.activeSubscriptionInfoList.orEmpty()
                    .any { it.subscriptionId == subscriptionId }
                if (!active) null else SmsManager.getSmsManagerForSubscriptionId(
                    subscriptionId,
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                activity.getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }
        } catch (_: Throwable) {
            null
        }
        if (smsManager == null) {
            result.success(mapOf("status" to "unavailable"))
            return
        }
        val parts = smsManager.divideMessage(body)
        val token = UUID.randomUUID().toString()
        val action = "${activity.packageName}.SMS_SENT.$token"
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                val current = pendingSend ?: return
                current.record(resultCode == Activity.RESULT_OK)
            }
        }
        val filter = IntentFilter(action)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                activity.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("DEPRECATION")
                activity.registerReceiver(receiver, filter)
            }
            val totalParts = recipients.size * parts.size
            val pending = PendingSend(
                receiver = receiver,
                expected = totalParts,
                result = result,
            )
            pendingSend = pending
            var requestCode = 0
            for (recipient in recipients) {
                val sentIntents = ArrayList<PendingIntent>(parts.size)
                parts.forEach {
                    val pendingIntent = PendingIntent.getBroadcast(
                        activity,
                        PERMISSION_REQUEST_CODE + requestCode++,
                        Intent(action).setPackage(activity.packageName),
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    sentIntents += pendingIntent
                }
                if (parts.size == 1) {
                    @Suppress("DEPRECATION")
                    smsManager.sendTextMessage(recipient, null, parts[0], sentIntents[0], null)
                } else {
                    @Suppress("DEPRECATION")
                    smsManager.sendMultipartTextMessage(recipient, null, parts, sentIntents, null)
                }
            }
            pending.timeout()
        } catch (error: SecurityException) {
            unregister(receiver)
            pendingSend = null
            result.success(mapOf("status" to "permission_denied"))
        } catch (_: Throwable) {
            unregister(receiver)
            pendingSend = null
            result.success(mapOf("status" to "failed"))
        }
    }

    private fun unregister(receiver: BroadcastReceiver) {
        try {
            activity.unregisterReceiver(receiver)
        } catch (_: IllegalArgumentException) {
            // Receiver was already unregistered after timeout or completion.
        }
    }

    private inner class PendingSend(
        private val receiver: BroadcastReceiver,
        private val expected: Int,
        private val result: MethodChannel.Result,
    ) {
        private var remaining = expected
        private var failed = false
        private var completed = false
        private var timeoutRunnable: Runnable? = null

        fun record(success: Boolean) {
            if (completed) return
            failed = failed || !success
            remaining--
            if (remaining <= 0) complete(if (failed) "failed" else "sent")
        }

        fun timeout() {
            timeoutRunnable = Runnable {
                if (!completed) complete("failed")
            }
            handler.postDelayed(timeoutRunnable!!, SEND_TIMEOUT_MS)
        }

        fun complete(status: String) {
            if (completed) return
            completed = true
            timeoutRunnable?.let(handler::removeCallbacks)
            unregister(receiver)
            if (pendingSend === this) pendingSend = null
            result.success(mapOf("status" to status))
        }
    }

    companion object {
        const val CHANNEL_NAME = "org.safemyanmar.mobile/sms"
        private const val PERMISSION_REQUEST_CODE = 4403
        private const val SIM_PERMISSION_REQUEST_CODE = 4404
        private const val SEND_TIMEOUT_MS = 45_000L
    }
}
