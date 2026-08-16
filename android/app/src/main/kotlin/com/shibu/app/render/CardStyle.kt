package com.shibu.app.render

import android.content.Context
import android.graphics.Color
import com.shibu.app.data.Prefs

/**
 * Everything the [CardRenderer] needs to know about how a card should look.
 *
 * The wallpaper and the home screen widget share the renderer but not their
 * settings, so each builds its own style from [Prefs].
 */
data class CardStyle(
    val textColor: Int,
    val fontScale: Float,
    val align: Align,
    val showReading: Boolean,
    val showMeaning: Boolean,
    val showExample: Boolean,
    val shadow: Boolean,
) {
    enum class Align { LEFT, CENTER, RIGHT }

    /** Secondary lines sit slightly back from the meaning. */
    val secondaryColor: Int
        get() = Color.argb(
            (Color.alpha(textColor) * 0.86f).toInt(),
            Color.red(textColor),
            Color.green(textColor),
            Color.blue(textColor),
        )

    companion object {
        fun forWallpaper(context: Context): CardStyle {
            val p = Prefs(context)
            return CardStyle(
                textColor = p.textColor,
                fontScale = p.fontScale,
                align = parseAlign(p.align),
                showReading = p.showReading,
                showMeaning = p.showMeaning,
                showExample = p.showExample,
                shadow = p.shadow,
            )
        }

        fun forWidget(context: Context): CardStyle {
            val p = Prefs(context)
            return CardStyle(
                textColor = p.widgetTextColor,
                fontScale = p.fontScale,
                align = Align.LEFT,
                showReading = p.showReading,
                showMeaning = p.showMeaning,
                showExample = p.showExample,
                // The widget paints its own background, so a shadow is only
                // needed when that background is see-through.
                shadow = p.widgetBackground == Prefs.WIDGET_BG_TRANSPARENT,
            )
        }

        private fun parseAlign(value: String): Align = when (value) {
            Prefs.ALIGN_CENTER -> Align.CENTER
            Prefs.ALIGN_RIGHT -> Align.RIGHT
            else -> Align.LEFT
        }
    }
}
