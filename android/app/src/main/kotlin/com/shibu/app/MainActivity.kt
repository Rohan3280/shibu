package com.shibu.app

import com.shibu.app.bridge.ShibuChannel
import com.shibu.app.rotation.Scheduler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ShibuChannel.CHANNEL,
        ).setMethodCallHandler(ShibuChannel(this))

        Scheduler.ensureScheduled(applicationContext)
    }
}
