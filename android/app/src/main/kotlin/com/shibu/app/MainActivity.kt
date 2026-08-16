package com.shibu.app

import android.content.Intent
import com.shibu.app.bridge.ShibuChannel
import com.shibu.app.rotation.Scheduler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var channel: ShibuChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val handler = ShibuChannel(this)
        channel = handler

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            ShibuChannel.CHANNEL,
        ).setMethodCallHandler(handler)

        Scheduler.ensureScheduled(applicationContext)
    }

    /**
     * The background picker is launched with startActivityForResult rather than
     * through a plugin, so its result has to be handed back by hand.
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (channel?.onActivityResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }
}
