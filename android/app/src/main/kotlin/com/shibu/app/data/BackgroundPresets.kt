package com.shibu.app.data

/**
 * Built-in gradient backdrops, so the wallpaper looks deliberate before the
 * user picks a photo of their own.
 *
 * Every preset is dark enough for white card text at the default dim level;
 * that is the whole selection criterion. The Dart twin lives at
 * `lib/models/background_presets.dart` and must be kept in step — the in-app
 * preview draws from it.
 */
object BackgroundPresets {

    const val DEFAULT_ID = "midnight"

    /** Vertical gradient stops, top to bottom. */
    data class Preset(val id: String, val label: String, val colors: IntArray) {
        // IntArray in a data class needs these written out by hand.
        override fun equals(other: Any?): Boolean =
            this === other || (other is Preset && id == other.id)

        override fun hashCode(): Int = id.hashCode()
    }

    val all: List<Preset> = listOf(
        Preset("midnight", "Midnight", intArrayOf(0xFF1E2A3A.toInt(), 0xFF0A0E14.toInt())),
        Preset("fuji", "Fuji", intArrayOf(0xFF4A5891.toInt(), 0xFF1B2140.toInt())),
        Preset("sumi", "Sumi ink", intArrayOf(0xFF33333A.toInt(), 0xFF0F0F12.toInt())),
        Preset("sakura", "Sakura night", intArrayOf(0xFF7A4560.toInt(), 0xFF241320.toInt())),
        Preset("matcha", "Matcha", intArrayOf(0xFF2F5D50.toInt(), 0xFF0E201B.toInt())),
        Preset("dusk", "Dusk", intArrayOf(0xFF6B4470.toInt(), 0xFF1E1630.toInt())),
        Preset("ocean", "Deep water", intArrayOf(0xFF1E4F6B.toInt(), 0xFF081720.toInt())),
    )

    fun byId(id: String?): Preset =
        all.firstOrNull { it.id == id } ?: all.first { it.id == DEFAULT_ID }
}
