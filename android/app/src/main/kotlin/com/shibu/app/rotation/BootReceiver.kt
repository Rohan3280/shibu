package com.shibu.app.rotation

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * Re-arms the rotation heartbeat after a reboot or an app update.
 *
 * WorkManager already restores its own jobs, but a package replacement can
 * leave the widget showing a stale card, so this also forces a redraw.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            -> {
                Scheduler.ensureScheduled(context)
                RotationEngine.refresh(context)
            }
        }
    }
}
