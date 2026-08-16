package com.shibu.app.rotation

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

/** Owns the background heartbeat that drives interval rotation. */
object Scheduler {

    /**
     * The shortest period WorkManager accepts. Rotation intervals longer than
     * this are handled by the worker checking elapsed time and doing nothing
     * until the interval is actually up.
     */
    private const val HEARTBEAT_MINUTES = 15L

    fun ensureScheduled(context: Context) {
        val request = PeriodicWorkRequestBuilder<RotationWorker>(
            HEARTBEAT_MINUTES, TimeUnit.MINUTES,
        ).build()

        WorkManager.getInstance(context.applicationContext).enqueueUniquePeriodicWork(
            RotationWorker.WORK_NAME,
            // KEEP so that routine settings changes do not reset the timer and
            // push the next rotation a further 15 minutes out.
            ExistingPeriodicWorkPolicy.KEEP,
            request,
        )
    }

    fun cancel(context: Context) {
        WorkManager.getInstance(context.applicationContext)
            .cancelUniqueWork(RotationWorker.WORK_NAME)
    }
}
