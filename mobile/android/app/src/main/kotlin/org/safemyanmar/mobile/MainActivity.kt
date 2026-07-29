package org.safemyanmar.mobile

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.safemyanmar.mobile.ai.NativeAiBridge

class MainActivity : FlutterActivity() {
    private var aiBridge: NativeAiBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        aiBridge = NativeAiBridge(applicationContext).also { bridge ->
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NativeAiBridge.CHANNEL_NAME)
                .setMethodCallHandler(bridge)
        }
    }

    override fun onDestroy() {
        aiBridge?.shutdownAsync()
        aiBridge = null
        super.onDestroy()
    }
}
