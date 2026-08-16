package com.shibu.app.data

import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color

/**
 * Every user-facing setting, in one place.
 *
 * Flutter and the native surfaces run in the same process, so a plain
 * [SharedPreferences] file is enough to share state: the app writes through the
 * method channel and the wallpaper engine and widget provider read straight
 * back out. Keys are stable strings because they are also written from Dart.
 */
class Prefs(context: Context) {

    private val sp: SharedPreferences =
        context.applicationContext.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    // Deck ------------------------------------------------------------------

    /** JLPT levels to draw from, e.g. {5, 4}. */
    var levels: Set<Int>
        get() = sp.getString(KEY_LEVELS, "5")
            ?.split(',')
            ?.mapNotNull { it.trim().toIntOrNull() }
            ?.toSet()
            ?: setOf(5)
        set(value) = sp.edit()
            .putString(KEY_LEVELS, value.sorted().joinToString(","))
            .apply()

    var deck: String
        get() = sp.getString(KEY_DECK, DECK_LEVELS) ?: DECK_LEVELS
        set(value) = sp.edit().putString(KEY_DECK, value).apply()

    var favorites: Set<Int>
        get() = readIntSet(KEY_FAVORITES)
        set(value) = writeIntSet(KEY_FAVORITES, value)

    var learned: Set<Int>
        get() = readIntSet(KEY_LEARNED)
        set(value) = writeIntSet(KEY_LEARNED, value)

    // Rotation --------------------------------------------------------------

    /** [ROTATION_UNLOCK] or [ROTATION_INTERVAL]. */
    var rotationMode: String
        get() = sp.getString(KEY_ROTATION_MODE, ROTATION_INTERVAL) ?: ROTATION_INTERVAL
        set(value) = sp.edit().putString(KEY_ROTATION_MODE, value).apply()

    /** How long a card stays up, in minutes, when rotating on an interval. */
    var intervalMinutes: Int
        get() = sp.getInt(KEY_INTERVAL_MINUTES, 60)
        set(value) = sp.edit().putInt(KEY_INTERVAL_MINUTES, value.coerceAtLeast(1)).apply()

    var shuffle: Boolean
        get() = sp.getBoolean(KEY_SHUFFLE, true)
        set(value) = sp.edit().putBoolean(KEY_SHUFFLE, value).apply()

    var shuffleSeed: Long
        get() = sp.getLong(KEY_SHUFFLE_SEED, DEFAULT_SEED)
        set(value) = sp.edit().putLong(KEY_SHUFFLE_SEED, value).apply()

    var currentIndex: Int
        get() = sp.getInt(KEY_CURRENT_INDEX, 0)
        set(value) = sp.edit().putInt(KEY_CURRENT_INDEX, value).apply()

    var lastRotationAt: Long
        get() = sp.getLong(KEY_LAST_ROTATION, 0L)
        set(value) = sp.edit().putLong(KEY_LAST_ROTATION, value).apply()

    // Card contents ---------------------------------------------------------

    var showReading: Boolean
        get() = sp.getBoolean(KEY_SHOW_READING, true)
        set(value) = sp.edit().putBoolean(KEY_SHOW_READING, value).apply()

    var showMeaning: Boolean
        get() = sp.getBoolean(KEY_SHOW_MEANING, true)
        set(value) = sp.edit().putBoolean(KEY_SHOW_MEANING, value).apply()

    var showExample: Boolean
        get() = sp.getBoolean(KEY_SHOW_EXAMPLE, true)
        set(value) = sp.edit().putBoolean(KEY_SHOW_EXAMPLE, value).apply()

    // Card appearance -------------------------------------------------------

    var textColor: Int
        get() = sp.getInt(KEY_TEXT_COLOR, Color.WHITE)
        set(value) = sp.edit().putInt(KEY_TEXT_COLOR, value).apply()

    /** Multiplies every text size on the card; 1.0 is the designed size. */
    var fontScale: Float
        get() = sp.getFloat(KEY_FONT_SCALE, 1.0f)
        set(value) = sp.edit().putFloat(KEY_FONT_SCALE, value.coerceIn(0.6f, 1.8f)).apply()

    /** "left", "center" or "right". */
    var align: String
        get() = sp.getString(KEY_ALIGN, ALIGN_LEFT) ?: ALIGN_LEFT
        set(value) = sp.edit().putString(KEY_ALIGN, value).apply()

    /** Vertical position on the wallpaper as a fraction of screen height. */
    var offsetY: Float
        get() = sp.getFloat(KEY_OFFSET_Y, 0.32f)
        set(value) = sp.edit().putFloat(KEY_OFFSET_Y, value.coerceIn(0f, 1f)).apply()

    /** Horizontal inset as a fraction of screen width. */
    var offsetX: Float
        get() = sp.getFloat(KEY_OFFSET_X, 0.06f)
        set(value) = sp.edit().putFloat(KEY_OFFSET_X, value.coerceIn(0f, 0.5f)).apply()

    /** A drop shadow keeps light text readable over a busy photo. */
    var shadow: Boolean
        get() = sp.getBoolean(KEY_SHADOW, true)
        set(value) = sp.edit().putBoolean(KEY_SHADOW, value).apply()

    // Wallpaper -------------------------------------------------------------

    /** [BACKGROUND_PRESET] or [BACKGROUND_IMAGE]. */
    var backgroundKind: String
        get() = sp.getString(KEY_BACKGROUND_KIND, BACKGROUND_PRESET) ?: BACKGROUND_PRESET
        set(value) = sp.edit().putString(KEY_BACKGROUND_KIND, value).apply()

    /** Id of the built-in gradient; see [BackgroundPresets]. */
    var backgroundPreset: String
        get() = sp.getString(KEY_BACKGROUND_PRESET, BackgroundPresets.DEFAULT_ID)
            ?: BackgroundPresets.DEFAULT_ID
        set(value) = sp.edit().putString(KEY_BACKGROUND_PRESET, value).apply()

    /**
     * Whether an animated background actually animates.
     *
     * A moving wallpaper redraws continuously whenever the screen is on, which
     * costs real battery, so this stays user-controlled. Turning it off shows
     * the first frame as a still image.
     */
    var backgroundAnimate: Boolean
        get() = sp.getBoolean(KEY_BACKGROUND_ANIMATE, true)
        set(value) = sp.edit().putBoolean(KEY_BACKGROUND_ANIMATE, value).apply()

    /** Absolute path of the background image or GIF copied into app storage. */
    var wallpaperPath: String?
        get() = sp.getString(KEY_WALLPAPER_PATH, null)
        set(value) = sp.edit().putString(KEY_WALLPAPER_PATH, value).apply()

    /** How much the background is darkened behind the card, 0..1. */
    var wallpaperDim: Float
        get() = sp.getFloat(KEY_WALLPAPER_DIM, 0.15f)
        set(value) = sp.edit().putFloat(KEY_WALLPAPER_DIM, value.coerceIn(0f, 0.8f)).apply()

    /** Fallback colour used when no background image has been chosen. */
    var wallpaperColor: Int
        get() = sp.getInt(KEY_WALLPAPER_COLOR, DEFAULT_WALLPAPER_COLOR)
        set(value) = sp.edit().putInt(KEY_WALLPAPER_COLOR, value).apply()

    // Home screen widget ----------------------------------------------------

    /** [WIDGET_BG_TRANSPARENT], [WIDGET_BG_SCRIM] or [WIDGET_BG_SOLID]. */
    var widgetBackground: String
        get() = sp.getString(KEY_WIDGET_BG, WIDGET_BG_SCRIM) ?: WIDGET_BG_SCRIM
        set(value) = sp.edit().putString(KEY_WIDGET_BG, value).apply()

    var widgetBackgroundColor: Int
        get() = sp.getInt(KEY_WIDGET_BG_COLOR, DEFAULT_WIDGET_BG_COLOR)
        set(value) = sp.edit().putInt(KEY_WIDGET_BG_COLOR, value).apply()

    var widgetTextColor: Int
        get() = sp.getInt(KEY_WIDGET_TEXT_COLOR, Color.WHITE)
        set(value) = sp.edit().putInt(KEY_WIDGET_TEXT_COLOR, value).apply()

    // Onboarding ------------------------------------------------------------

    var onboarded: Boolean
        get() = sp.getBoolean(KEY_ONBOARDED, false)
        set(value) = sp.edit().putBoolean(KEY_ONBOARDED, value).apply()

    // Helpers ---------------------------------------------------------------

    private fun readIntSet(key: String): Set<Int> =
        sp.getString(key, "")
            ?.split(',')
            ?.mapNotNull { it.trim().toIntOrNull() }
            ?.toSet()
            ?: emptySet()

    private fun writeIntSet(key: String, value: Set<Int>) {
        sp.edit().putString(key, value.sorted().joinToString(",")).apply()
    }

    companion object {
        const val FILE = "shibu_settings"

        const val DECK_LEVELS = "levels"
        const val DECK_FAVORITES = "favorites"

        const val ROTATION_UNLOCK = "unlock"
        const val ROTATION_INTERVAL = "interval"

        const val ALIGN_LEFT = "left"
        const val ALIGN_CENTER = "center"
        const val ALIGN_RIGHT = "right"

        const val BACKGROUND_PRESET = "preset"
        const val BACKGROUND_IMAGE = "image"

        const val WIDGET_BG_TRANSPARENT = "transparent"
        const val WIDGET_BG_SCRIM = "scrim"
        const val WIDGET_BG_SOLID = "solid"

        private const val DEFAULT_SEED = 20240623L
        private const val DEFAULT_WALLPAPER_COLOR = 0xFF16202C.toInt()
        private const val DEFAULT_WIDGET_BG_COLOR = 0xCC101820.toInt()

        private const val KEY_LEVELS = "levels"
        private const val KEY_DECK = "deck"
        private const val KEY_FAVORITES = "favorites"
        private const val KEY_LEARNED = "learned"
        private const val KEY_ROTATION_MODE = "rotation_mode"
        private const val KEY_INTERVAL_MINUTES = "interval_minutes"
        private const val KEY_SHUFFLE = "shuffle"
        private const val KEY_SHUFFLE_SEED = "shuffle_seed"
        private const val KEY_CURRENT_INDEX = "current_index"
        private const val KEY_LAST_ROTATION = "last_rotation_at"
        private const val KEY_SHOW_READING = "show_reading"
        private const val KEY_SHOW_MEANING = "show_meaning"
        private const val KEY_SHOW_EXAMPLE = "show_example"
        private const val KEY_TEXT_COLOR = "text_color"
        private const val KEY_FONT_SCALE = "font_scale"
        private const val KEY_ALIGN = "align"
        private const val KEY_OFFSET_Y = "offset_y"
        private const val KEY_OFFSET_X = "offset_x"
        private const val KEY_SHADOW = "shadow"
        private const val KEY_BACKGROUND_KIND = "background_kind"
        private const val KEY_BACKGROUND_PRESET = "background_preset"
        private const val KEY_BACKGROUND_ANIMATE = "background_animate"
        private const val KEY_WALLPAPER_PATH = "wallpaper_path"
        private const val KEY_WALLPAPER_DIM = "wallpaper_dim"
        private const val KEY_WALLPAPER_COLOR = "wallpaper_color"
        private const val KEY_WIDGET_BG = "widget_bg"
        private const val KEY_WIDGET_BG_COLOR = "widget_bg_color"
        private const val KEY_WIDGET_TEXT_COLOR = "widget_text_color"
        private const val KEY_ONBOARDED = "onboarded"
    }
}
