package com.shibu.app.bridge

import android.app.Activity
import android.app.WallpaperManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import com.shibu.app.data.KanjiStore
import com.shibu.app.data.Prefs
import com.shibu.app.rotation.RotationEngine
import com.shibu.app.rotation.Scheduler
import com.shibu.app.wallpaper.ShibuWallpaperService
import com.shibu.app.widget.ShibuWidgetProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * The single bridge between the Flutter UI and the native surfaces.
 *
 * Settings live in [Prefs] rather than in Dart so that the wallpaper engine and
 * the widget provider — which run without a Flutter engine attached — can read
 * them directly. Dart writes through [applySettings] and reads back through
 * [readSettings].
 */
class ShibuChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {

    private val context: Context get() = activity.applicationContext

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "readSettings" -> result.success(readSettings())
                "applySettings" -> {
                    applySettings(call)
                    result.success(readSettings())
                }
                "currentKanjiId" -> result.success(KanjiStore.current(context)?.id ?: -1)
                "nextKanji" -> {
                    RotationEngine.next(context)
                    result.success(KanjiStore.current(context)?.id ?: -1)
                }
                "previousKanji" -> {
                    RotationEngine.previous(context)
                    result.success(KanjiStore.current(context)?.id ?: -1)
                }
                "showKanji" -> {
                    val id = call.argument<Int>("id") ?: -1
                    result.success(RotationEngine.showKanji(context, id))
                }
                "refreshSurfaces" -> {
                    RotationEngine.refresh(context)
                    result.success(true)
                }
                "setBackgroundImage" -> result.success(copyBackground(call.argument("path")))
                "clearBackgroundImage" -> {
                    Prefs(context).wallpaperPath = null
                    notifyBackgroundChanged()
                    result.success(true)
                }
                "openWallpaperPicker" -> result.success(openWallpaperPicker())
                "isWallpaperActive" -> result.success(isWallpaperActive())
                "requestPinWidget" -> result.success(requestPinWidget())
                "widgetCount" -> result.success(widgetCount())
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e(TAG, "method ${call.method} failed", e)
            result.error("shibu_error", e.message, null)
        }
    }

    // Settings --------------------------------------------------------------

    private fun readSettings(): Map<String, Any?> {
        val p = Prefs(context)
        return mapOf(
            "levels" to p.levels.sorted(),
            "deck" to p.deck,
            "favorites" to p.favorites.sorted(),
            "learned" to p.learned.sorted(),
            "rotationMode" to p.rotationMode,
            "intervalMinutes" to p.intervalMinutes,
            "shuffle" to p.shuffle,
            "currentIndex" to p.currentIndex,
            "showReading" to p.showReading,
            "showMeaning" to p.showMeaning,
            "showExample" to p.showExample,
            "textColor" to p.textColor,
            "fontScale" to p.fontScale.toDouble(),
            "align" to p.align,
            "offsetX" to p.offsetX.toDouble(),
            "offsetY" to p.offsetY.toDouble(),
            "shadow" to p.shadow,
            "wallpaperPath" to p.wallpaperPath,
            "wallpaperDim" to p.wallpaperDim.toDouble(),
            "wallpaperColor" to p.wallpaperColor,
            "widgetBackground" to p.widgetBackground,
            "widgetTextColor" to p.widgetTextColor,
            "onboarded" to p.onboarded,
        )
    }

    private fun applySettings(call: MethodCall) {
        val p = Prefs(context)
        var deckChanged = false

        call.argument<List<Int>>("levels")?.let {
            val levels = it.toSet()
            if (levels != p.levels) deckChanged = true
            p.levels = levels
        }
        call.argument<String>("deck")?.let {
            if (it != p.deck) deckChanged = true
            p.deck = it
        }
        call.argument<List<Int>>("favorites")?.let {
            if (p.deck == Prefs.DECK_FAVORITES && it.toSet() != p.favorites) deckChanged = true
            p.favorites = it.toSet()
        }
        call.argument<List<Int>>("learned")?.let { p.learned = it.toSet() }
        call.argument<String>("rotationMode")?.let { p.rotationMode = it }
        call.argument<Int>("intervalMinutes")?.let { p.intervalMinutes = it }
        call.argument<Boolean>("shuffle")?.let {
            if (it != p.shuffle) deckChanged = true
            p.shuffle = it
        }
        call.argument<Boolean>("showReading")?.let { p.showReading = it }
        call.argument<Boolean>("showMeaning")?.let { p.showMeaning = it }
        call.argument<Boolean>("showExample")?.let { p.showExample = it }
        call.argument<Int>("textColor")?.let { p.textColor = it }
        call.argument<Double>("fontScale")?.let { p.fontScale = it.toFloat() }
        call.argument<String>("align")?.let { p.align = it }
        call.argument<Double>("offsetX")?.let { p.offsetX = it.toFloat() }
        call.argument<Double>("offsetY")?.let { p.offsetY = it.toFloat() }
        call.argument<Boolean>("shadow")?.let { p.shadow = it }
        call.argument<Double>("wallpaperDim")?.let { p.wallpaperDim = it.toFloat() }
        call.argument<Int>("wallpaperColor")?.let { p.wallpaperColor = it }
        call.argument<String>("widgetBackground")?.let { p.widgetBackground = it }
        call.argument<Int>("widgetTextColor")?.let { p.widgetTextColor = it }
        call.argument<Boolean>("onboarded")?.let { p.onboarded = it }

        // Changing the deck invalidates the current position: index 40 of an
        // N5-only deck means a different kanji once N4 is added.
        if (deckChanged) {
            p.currentIndex = 0
            p.lastRotationAt = System.currentTimeMillis()
        }

        Scheduler.ensureScheduled(context)
        RotationEngine.refresh(context)
    }

    // Background image ------------------------------------------------------

    /**
     * Stores the chosen photo inside app storage.
     *
     * Copying rather than holding a content URI means the wallpaper engine
     * needs no storage permission and keeps working if the user later moves or
     * deletes the original from their gallery.
     */
    private fun copyBackground(sourcePath: String?): String? {
        val source = sourcePath?.let(::File) ?: return null
        if (!source.exists()) return null

        val dir = File(context.filesDir, "wallpaper").apply { mkdirs() }
        val target = File(dir, "background.jpg")
        source.inputStream().use { input ->
            FileOutputStream(target).use { output -> input.copyTo(output) }
        }

        Prefs(context).wallpaperPath = target.absolutePath
        notifyBackgroundChanged()
        return target.absolutePath
    }

    private fun notifyBackgroundChanged() {
        context.sendBroadcast(
            Intent(RotationEngine.ACTION_CARD_CHANGED)
                .setPackage(context.packageName)
                .putExtra(ShibuWallpaperService.EXTRA_RELOAD_BACKGROUND, true)
        )
        ShibuWidgetProvider.refreshAll(context)
    }

    // System integration ----------------------------------------------------

    private fun openWallpaperPicker(): Boolean = try {
        activity.startActivity(ShibuWallpaperService.pickerIntent(context))
        true
    } catch (e: Exception) {
        Log.w(TAG, "live wallpaper picker unavailable", e)
        // Some OEM builds hide the direct picker; fall back to the generic one.
        runCatching {
            activity.startActivity(Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER))
        }.isSuccess
    }

    private fun isWallpaperActive(): Boolean = runCatching {
        WallpaperManager.getInstance(context).wallpaperInfo?.packageName == context.packageName
    }.getOrDefault(false)

    /**
     * Asks the launcher to place the widget. Only supported on Android 8+ and
     * only by launchers that opt in, so the UI treats false as "add it
     * yourself from the widget tray".
     */
    private fun requestPinWidget(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val manager = AppWidgetManager.getInstance(context)
        val provider = ComponentName(context, ShibuWidgetProvider::class.java)
        if (!manager.isRequestPinAppWidgetSupported) return false
        return manager.requestPinAppWidget(provider, null, null)
    }

    private fun widgetCount(): Int = AppWidgetManager.getInstance(context)
        .getAppWidgetIds(ComponentName(context, ShibuWidgetProvider::class.java))
        .size

    companion object {
        const val CHANNEL = "com.shibu.app/bridge"
        private const val TAG = "ShibuChannel"
    }
}
