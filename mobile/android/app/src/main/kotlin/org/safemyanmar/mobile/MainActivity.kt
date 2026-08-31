package org.safemyanmar.mobile

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.safemyanmar.mobile.ai.NativeAiBridge
import org.safemyanmar.mobile.sos.SosBleBridge
import org.safemyanmar.mobile.sos.NativeSmsBridge

class MainActivity : FlutterActivity() {
    private var aiBridge: NativeAiBridge? = null
    private var sosBleBridge: SosBleBridge? = null
    private var smsBridge: NativeSmsBridge? = null

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        sosBleBridge?.onNewIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        aiBridge = NativeAiBridge(applicationContext).also { bridge ->
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeAiBridge.CHANNEL_NAME)
                .setMethodCallHandler(bridge)
        }
        sosBleBridge = SosBleBridge(this).also { bridge ->
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SosBleBridge.CHANNEL_NAME)
                .setMethodCallHandler(bridge)
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, SosBleBridge.EVENT_CHANNEL_NAME)
                .setStreamHandler(bridge)
            EventChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                SosBleBridge.NOTIFICATION_EVENT_CHANNEL_NAME,
            ).setStreamHandler(bridge.notificationEventStreamHandler)
        }
        smsBridge = NativeSmsBridge(this).also { bridge ->
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeSmsBridge.CHANNEL_NAME)
                .setMethodCallHandler(bridge)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        val handled =
            sosBleBridge?.onRequestPermissionsResult(requestCode, permissions, grantResults) == true ||
                smsBridge?.onRequestPermissionsResult(requestCode, permissions, grantResults) == true
        if (!handled) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    override fun onDestroy() {
        aiBridge?.shutdownAsync()
        aiBridge = null
        sosBleBridge?.close()
        sosBleBridge = null
        smsBridge?.close()
        smsBridge = null
        super.onDestroy()
    }

    companion object {
        const val EXTRA_SOS_EVENT_ID = "sos_event_id"
    }
}
