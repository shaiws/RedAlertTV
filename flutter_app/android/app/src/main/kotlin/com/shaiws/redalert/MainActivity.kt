package com.shaiws.redalert

import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channel = "com.shaiws.redalert/platform"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAndroidTV" -> {
                        val isTV = packageManager.hasSystemFeature(
                            PackageManager.FEATURE_LEANBACK
                        )
                        result.success(isTV)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
