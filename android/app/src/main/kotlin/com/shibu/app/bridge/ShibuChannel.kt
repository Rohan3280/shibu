package com.shibu.app.bridge

import android.app.Activity
import android.app.WallpaperManager
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import com.shibu.app.data.BackgroundPresets
import com.shibu.app.data.KanjiStore
import com.shibu.app.data.Prefs
import com.shibu.app.rotation.RotationEngine
import com.shibu.app.rotation.Scheduler
import com.shibu.app.wallpaper.ShibuWallpaperService
import com.shibu.app.widget.ShibuWidgetProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

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

    /** Held while the system document picker is open. */
    private var pendingPick: MethodChannel.Result? = null

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
                "pickBackground" -> pickBackground(result)
                "clearBackground" -> {
                    BackgroundStore.clear(context)
                    notifyBackgroundChanged()
                    result.success(true)
                }
                "backgroundPresets" -> result.success(presets())
                "openWallpaperPicker" -> result.success(openWallpaperPicker())
                "isWallpaperActive" -> result.success(isWallpaperActive())
                "activeWallpaperName" -> result.success(activeWallpaperName())
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
            "backgroundKind" to p.backgroundKind,
            "backgroundPreset" to p.backgroundPreset,
            "backgroundAnimate" to p.backgroundAnimate,
            "backgroundIsAnimated" to BackgroundStore.isStoredAnimated(context),
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
        var backdropChanged = false

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
        call.intArg("intervalMinutes")?.let { p.intervalMinutes = it }
        call.argument<Boolean>("shuffle")?.let {
            if (it != p.shuffle) deckChanged = true
            p.shuffle = it
        }
        call.argument<Boolean>("showReading")?.let { p.showReading = it }
        call.argument<Boolean>("showMeaning")?.let { p.showMeaning = it }
        call.argument<Boolean>("showExample")?.let { p.showExample = it }
        call.intArg("textColor")?.let { p.textColor = it }
        call.floatArg("fontScale")?.let { p.fontScale = it }
        call.argument<String>("align")?.let { p.align = it }
        call.floatArg("offsetX")?.let { p.offsetX = it }
        call.floatArg("offsetY")?.let { p.offsetY = it }
        call.argument<Boolean>("shadow")?.let { p.shadow = it }
        call.argument<String>("backgroundKind")?.let {
            if (it != p.backgroundKind) backdropChanged = true
            p.backgroundKind = it
        }
        call.argument<String>("backgroundPreset")?.let {
            if (it != p.backgroundPreset) backdropChanged = true
            p.backgroundPreset = it
        }
        call.argument<Boolean>("backgroundAnimate")?.let {
            if (it != p.backgroundAnimate) backdropChanged = true
            p.backgroundAnimate = it
        }
        call.floatArg("wallpaperDim")?.let { p.wallpaperDim = it }
        call.intArg("wallpaperColor")?.let { p.wallpaperColor = it }
        call.argument<String>("widgetBackground")?.let { p.widgetBackground = it }
        call.intArg("widgetTextColor")?.let { p.widgetTextColor = it }
        call.argument<Boolean>("onboarded")?.let { p.onboarded = it }

        // Changing the deck invalidates the current position: index 40 of an
        // N5-only deck means a different kanji once N4 is added.
        if (deckChanged) {
            p.currentIndex = 0
            p.lastRotationAt = System.currentTimeMillis()
        }

        Scheduler.ensureScheduled(context)
        if (backdropChanged) {
            notifyBackgroundChanged()
        } else {
            RotationEngine.refresh(context)
        }
    }

    private fun presets(): List<Map<String, Any>> = BackgroundPresets.all.map {
        mapOf("id" to it.id, "label" to it.label, "colors" to it.colors.toList())
    }

    // Background image ------------------------------------------------------

    /**
     * Opens the system document picker.
     *
     * ACTION_OPEN_DOCUMENT rather than a gallery plugin, because the bytes have
     * to reach [BackgroundStore] untouched — anything that re-encodes would
     * turn an animated GIF into a still frame.
     */
    private fun pickBackground(result: MethodChannel.Result) {
        pendingPick?.success(null)
        pendingPick = result

        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("image/*")
            .putExtra(
                Intent.EXTRA_MIME_TYPES,
                arrayOf("image/jpeg", "image/png", "image/gif", "image/webp", "image/heif"),
            )

        try {
            activity.startActivityForResult(intent, REQUEST_PICK_BACKGROUND)
        } catch (e: Exception) {
            Log.e(TAG, "no document picker available", e)
            pendingPick = null
            result.error("no_picker", "No app on this device can pick an image.", null)
        }
    }

    /** Called by MainActivity. Returns true when the result was consumed. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK_BACKGROUND) return false

        val result = pendingPick ?: return true
        pendingPick = null

        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            // The user backed out; not an error.
            result.success(null)
            return true
        }

        val stored = BackgroundStore.save(context, uri)
        if (stored == null) {
            result.error("copy_failed", "Could not read that image.", null)
        } else {
            notifyBackgroundChanged()
            result.success(mapOf("path" to stored.path, "animated" to stored.animated))
        }
        return true
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
     * Label of whatever live wallpaper is currently running, or null for a
     * plain image wallpaper. Used to explain *why* Shibu is not on screen when
     * another app owns the wallpaper.
     */
    private fun activeWallpaperName(): String? = runCatching {
        val info = WallpaperManager.getInstance(context).wallpaperInfo ?: return null
        if (info.packageName == context.packageName) return null
        info.loadLabel(context.packageManager)?.toString()
    }.getOrNull()

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

    /**
     * Reads a numeric argument without caring how the codec sized it.
     *
     * The standard message codec promotes any Dart int above 2^31 to Int64, so
     * an opaque ARGB colour arrives as a Long while a small integer arrives as
     * an Int. Asking for a concrete type threw ClassCastException and aborted
     * the whole write, which silently discarded every setting on the call.
     */
    private fun MethodCall.intArg(name: String): Int? =
        (argument<Any>(name) as? Number)?.toLong()?.toInt()

    private fun MethodCall.floatArg(name: String): Float? =
        (argument<Any>(name) as? Number)?.toFloat()

    companion object {
        const val CHANNEL = "com.shibu.app/bridge"
        private const val TAG = "ShibuChannel"
        private const val REQUEST_PICK_BACKGROUND = 4801
    }
}
