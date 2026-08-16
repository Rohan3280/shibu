package com.shibu.app.rotation

import android.content.Context
import android.content.Intent
import com.shibu.app.data.KanjiStore
import com.shibu.app.data.Prefs
import com.shibu.app.widget.ShibuWidgetProvider

/**
 * Decides when the displayed kanji should change, and tells every surface about
 * it.
 *
 * There is deliberately no timer here. Rotation is evaluated lazily whenever
 * something asks — the wallpaper becoming visible, the periodic worker running,
 * the widget being redrawn — and the elapsed time since [Prefs.lastRotationAt]
 * decides the outcome. That keeps the wallpaper and the widget on the same card
 * without them having to coordinate, and costs nothing while the screen is off.
 */
object RotationEngine {

    /** Broadcast so the wallpaper engine can repaint after a rotation. */
    const val ACTION_CARD_CHANGED = "com.shibu.app.CARD_CHANGED"

    enum class Trigger {
        /** The lock or home screen just became visible. */
        SCREEN_VISIBLE,

        /** The periodic background check fired. */
        PERIODIC,

        /** The user asked for a different card from inside the app. */
        MANUAL,
    }

    /**
     * Rotates if the current settings say it is due.
     *
     * @return true when the card actually changed.
     */
    @Synchronized
    fun maybeRotate(context: Context, trigger: Trigger): Boolean {
        val prefs = Prefs(context)
        val due = when (trigger) {
            Trigger.MANUAL -> true
            Trigger.SCREEN_VISIBLE ->
                prefs.rotationMode == Prefs.ROTATION_UNLOCK || intervalElapsed(prefs)
            Trigger.PERIODIC ->
                prefs.rotationMode == Prefs.ROTATION_INTERVAL && intervalElapsed(prefs)
        }
        if (!due) return false

        advance(context, prefs)
        notifySurfaces(context)
        return true
    }

    /** Unconditionally moves to the next card. */
    @Synchronized
    fun next(context: Context) {
        advance(context, Prefs(context))
        notifySurfaces(context)
    }

    /** Unconditionally moves to the previous card. */
    @Synchronized
    fun previous(context: Context) {
        val prefs = Prefs(context)
        val size = KanjiStore.orderedDeck(context).size
        if (size > 0) {
            prefs.currentIndex = Math.floorMod(prefs.currentIndex - 1, size)
        }
        prefs.lastRotationAt = System.currentTimeMillis()
        notifySurfaces(context)
    }

    /** Jumps straight to a specific kanji, e.g. from the browse screen. */
    @Synchronized
    fun showKanji(context: Context, kanjiId: Int): Boolean {
        val index = KanjiStore.orderedDeck(context).indexOfFirst { it.id == kanjiId }
        if (index < 0) return false

        val prefs = Prefs(context)
        prefs.currentIndex = index
        prefs.lastRotationAt = System.currentTimeMillis()
        notifySurfaces(context)
        return true
    }

    /**
     * Redraws every surface without changing the card. Used after a settings
     * change, where the content is the same but the styling is not.
     */
    fun refresh(context: Context) = notifySurfaces(context)

    private fun advance(context: Context, prefs: Prefs) {
        val size = KanjiStore.orderedDeck(context).size
        if (size > 0) {
            prefs.currentIndex = Math.floorMod(prefs.currentIndex + 1, size)
        }
        prefs.lastRotationAt = System.currentTimeMillis()
    }

    private fun intervalElapsed(prefs: Prefs): Boolean {
        val elapsed = System.currentTimeMillis() - prefs.lastRotationAt
        return elapsed >= prefs.intervalMinutes * 60_000L
    }

    private fun notifySurfaces(context: Context) {
        val app = context.applicationContext
        ShibuWidgetProvider.refreshAll(app)
        // Explicit package keeps this an internal broadcast on Android 8+.
        app.sendBroadcast(
            Intent(ACTION_CARD_CHANGED).setPackage(app.packageName)
        )
    }
}
