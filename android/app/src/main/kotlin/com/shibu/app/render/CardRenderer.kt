package com.shibu.app.render

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.text.Layout
import android.text.SpannableStringBuilder
import android.text.StaticLayout
import android.text.TextPaint
import android.text.style.AbsoluteSizeSpan
import android.text.style.ForegroundColorSpan
import android.text.style.StyleSpan
import android.util.DisplayMetrics
import android.util.TypedValue
import com.shibu.app.data.Kanji
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * Draws a kanji card: the character set large on the left, with its reading,
 * meaning and an example compound stacked to the right.
 *
 *     駅   eki・えき
 *          station
 *          駅前・in front of station
 *
 * The same renderer backs the live wallpaper and the home screen widget so both
 * surfaces stay pixel-identical. Nothing here touches settings directly —
 * callers pass a [CardStyle] — which also lets the in-app preview render a card
 * that is not the currently scheduled one.
 */
object CardRenderer {

    // Designed sizes, in sp, before the user's font scale is applied.
    private const val KANJI_SP = 46f
    private const val READING_SP = 13f
    private const val MEANING_SP = 17f
    private const val EXAMPLE_SP = 12f

    // Designed spacing, in dp.
    private const val COLUMN_GAP_DP = 14f
    private const val LINE_GAP_DP = 2f

    /** A laid-out card, ready to draw or measure. */
    class Card internal constructor(
        private val kanji: Kanji,
        private val style: CardStyle,
        private val kanjiPaint: TextPaint,
        private val textLayout: StaticLayout?,
        private val kanjiWidth: Float,
        private val columnGap: Float,
        val width: Int,
        val height: Int,
    ) {
        /** Draws the card with its top-left corner at ([left], [top]). */
        fun draw(canvas: Canvas, left: Float, top: Float) {
            val textHeight = textLayout?.height ?: 0

            // The character is optically centred against the text block.
            val kanjiMetrics = kanjiPaint.fontMetrics
            val kanjiHeight = kanjiMetrics.descent - kanjiMetrics.ascent
            val kanjiTop = top + max(0f, (textHeight - kanjiHeight) / 2f)
            val kanjiBaseline = kanjiTop - kanjiMetrics.ascent

            canvas.drawText(kanji.character, left, kanjiBaseline, kanjiPaint)

            if (textLayout != null) {
                val textLeft = left + kanjiWidth + columnGap
                val textTop = top + max(0f, (kanjiHeight - textHeight) / 2f)
                canvas.save()
                canvas.translate(textLeft, textTop)
                textLayout.draw(canvas)
                canvas.restore()
            }
        }

        /** Renders the card onto its own transparent bitmap. */
        fun toBitmap(padding: Int = 0): Bitmap {
            val bitmap = Bitmap.createBitmap(
                width + padding * 2,
                height + padding * 2,
                Bitmap.Config.ARGB_8888,
            )
            draw(Canvas(bitmap), padding.toFloat(), padding.toFloat())
            return bitmap
        }
    }

    /**
     * Lays out [kanji] within [maxWidth] pixels.
     *
     * [density] is passed explicitly rather than read from the context because
     * the widget renders against the launcher's cell size, not the display.
     */
    fun layout(
        context: Context,
        kanji: Kanji,
        style: CardStyle,
        maxWidth: Int,
    ): Card {
        val metrics = context.resources.displayMetrics
        val scale = style.fontScale

        val kanjiPaint = textPaint(
            sizePx = sp(metrics, KANJI_SP * scale),
            color = style.textColor,
            bold = false,
            shadow = style.shadow,
        )

        val kanjiWidth = kanjiPaint.measureText(kanji.character)
        val columnGap = dp(metrics, COLUMN_GAP_DP)

        val spanned = buildText(context, kanji, style, metrics, scale)
        val available = (maxWidth - kanjiWidth - columnGap).roundToInt()

        val textLayout = if (spanned.isEmpty() || available <= 0) {
            null
        } else {
            val paint = textPaint(
                sizePx = sp(metrics, MEANING_SP * scale),
                color = style.textColor,
                bold = false,
                shadow = style.shadow,
            )
            StaticLayout.Builder
                .obtain(spanned, 0, spanned.length, paint, available)
                .setAlignment(alignmentFor(style.align))
                .setLineSpacing(dp(metrics, LINE_GAP_DP), 1.0f)
                .setIncludePad(false)
                .build()
        }

        val kanjiMetrics = kanjiPaint.fontMetrics
        val kanjiHeight = kanjiMetrics.descent - kanjiMetrics.ascent

        val contentWidth = if (textLayout == null) {
            kanjiWidth
        } else {
            kanjiWidth + columnGap + widestLine(textLayout)
        }

        return Card(
            kanji = kanji,
            style = style,
            kanjiPaint = kanjiPaint,
            textLayout = textLayout,
            kanjiWidth = kanjiWidth,
            columnGap = columnGap,
            width = contentWidth.roundToInt().coerceAtMost(maxWidth),
            height = max(kanjiHeight, (textLayout?.height ?: 0).toFloat()).roundToInt(),
        )
    }

    /**
     * Builds the three text lines as one span so [StaticLayout] can wrap long
     * meanings without the caller measuring anything by hand.
     */
    private fun buildText(
        context: Context,
        kanji: Kanji,
        style: CardStyle,
        metrics: DisplayMetrics,
        scale: Float,
    ): SpannableStringBuilder {
        val builder = SpannableStringBuilder()

        if (style.showReading) {
            append(
                builder,
                kanji.readingLine,
                sp(metrics, READING_SP * scale).roundToInt(),
                bold = false,
                color = style.secondaryColor,
            )
        }
        if (style.showMeaning) {
            append(
                builder,
                kanji.meaning,
                sp(metrics, MEANING_SP * scale).roundToInt(),
                bold = true,
                color = style.textColor,
            )
        }
        if (style.showExample) {
            append(
                builder,
                kanji.exampleLine,
                sp(metrics, EXAMPLE_SP * scale).roundToInt(),
                bold = false,
                color = style.secondaryColor,
            )
        }
        return builder
    }

    private fun append(
        builder: SpannableStringBuilder,
        text: String,
        sizePx: Int,
        bold: Boolean,
        color: Int,
    ) {
        if (text.isBlank()) return
        if (builder.isNotEmpty()) builder.append('\n')

        val start = builder.length
        builder.append(text)
        val end = builder.length

        builder.setSpan(AbsoluteSizeSpan(sizePx), start, end, SPAN_FLAGS)
        builder.setSpan(ForegroundColorSpan(color), start, end, SPAN_FLAGS)
        if (bold) {
            builder.setSpan(StyleSpan(Typeface.BOLD), start, end, SPAN_FLAGS)
        }
    }

    private fun textPaint(sizePx: Float, color: Int, bold: Boolean, shadow: Boolean): TextPaint =
        TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = sizePx
            this.color = color
            typeface = Typeface.create(
                Typeface.SANS_SERIF,
                if (bold) Typeface.BOLD else Typeface.NORMAL,
            )
            if (shadow) {
                // Soft, offset slightly down: enough to hold light text against
                // a bright photo without looking like a hard drop shadow.
                setShadowLayer(sizePx * 0.14f, 0f, sizePx * 0.035f, SHADOW_COLOR)
            }
        }

    private fun widestLine(layout: StaticLayout): Float {
        var widest = 0f
        for (line in 0 until layout.lineCount) {
            widest = max(widest, layout.getLineWidth(line))
        }
        return widest
    }

    private fun alignmentFor(align: CardStyle.Align): Layout.Alignment = when (align) {
        CardStyle.Align.CENTER -> Layout.Alignment.ALIGN_CENTER
        CardStyle.Align.RIGHT -> Layout.Alignment.ALIGN_OPPOSITE
        CardStyle.Align.LEFT -> Layout.Alignment.ALIGN_NORMAL
    }

    private fun sp(metrics: DisplayMetrics, value: Float): Float =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, value, metrics)

    private fun dp(metrics: DisplayMetrics, value: Float): Float =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, metrics)

    private const val SPAN_FLAGS = SpannableStringBuilder.SPAN_EXCLUSIVE_EXCLUSIVE
    private val SHADOW_COLOR = Color.argb(140, 0, 0, 0)
}
