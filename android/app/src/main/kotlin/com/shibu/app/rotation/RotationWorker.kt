package com.shibu.app.rotation

import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * Periodic heartbeat that lets the home screen widget keep rotating while the
 * phone sits idle.
 *
 * WorkManager will not run a periodic job more often than every 15 minutes, so
 * this only decides *whether* a rotation is due rather than performing one on a
 * schedule of its own. A one hour interval is simply four heartbeats where the
 * first three do nothing.
 */
class RotationWorker(context: Context, params: WorkerParameters) : Worker(context, params) {

    override fun doWork(): Result {
        RotationEngine.maybeRotate(applicationContext, RotationEngine.Trigger.PERIODIC)
        return Result.success()
    }

    companion object {
        const val WORK_NAME = "shibu-rotation"
    }
}
