package com.shibu.app.wallpaper

import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Shader
import android.graphics.drawable.AnimatedImageDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import androidx.annotation.RequiresApi
import com.shibu.app.data.BackgroundPresets
import kotlin.math.max

/**
 * What gets painted behind the kanji card.
 *
 * Three shapes, deliberately kept apart because they have different costs: a
 * gradient is free, a still image is one decode, and an animated image has to
 * be redrawn continuously for as long as the wallpaper is visible.
 */
sealed interface Backdrop {

    fun draw(canvas: Canvas, width: Int, height: Int)

    /** True when this backdrop needs a repeating redraw to look right. */
    val isAnimated: Boolean get() = false

    fun release() {}

    /** A built-in gradient. Costs nothing to draw and never needs decoding. */
    class Gradient(presetId: String?) : Backdrop {
        private val colors = BackgroundPresets.byId(presetId).colors
        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        private var shaderHeight = 0

        override fun draw(canvas: Canvas, width: Int, height: Int) {
            if (shaderHeight != height) {
                paint.shader = LinearGradient(
                    0f, 0f, 0f, height.toFloat(),
                    colors, null, Shader.TileMode.CLAMP,
                )
                shaderHeight = height
            }
            canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        }
    }

    /**
     * A user-chosen photo, already scaled and centre-cropped to the surface by
     * the caller.
     */
    class Still(private val bitmap: android.graphics.Bitmap) : Backdrop {
        private val paint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)

        override fun draw(canvas: Canvas, width: Int, height: Int) {
            canvas.drawBitmap(bitmap, 0f, 0f, paint)
        }

        override fun release() {
            if (!bitmap.isRecycled) bitmap.recycle()
        }
    }

    /**
     * A GIF or animated WebP.
     *
     * [AnimatedImageDrawable] advances its own frame clock as it is drawn, so
     * the engine only has to keep asking it to draw. Centre-cropping is done
     * with a canvas transform rather than by scaling the drawable, which keeps
     * the decoder working at its target size.
     */
    @RequiresApi(Build.VERSION_CODES.P)
    class Animated(
        private val drawable: AnimatedImageDrawable,
        private val animate: Boolean,
    ) : Backdrop {

        init {
            drawable.repeatCount = AnimatedImageDrawable.REPEAT_INFINITE
            if (animate) drawable.start() else drawable.stop()
        }

        override val isAnimated: Boolean get() = animate

        override fun draw(canvas: Canvas, width: Int, height: Int) {
            drawScaled(canvas, drawable, width, height)
        }

        override fun release() {
            drawable.stop()
        }
    }

    companion object {
        /** Centre-crops [drawable] to fill a [width] x [height] surface. */
        fun drawScaled(canvas: Canvas, drawable: Drawable, width: Int, height: Int) {
            val srcW = drawable.intrinsicWidth.takeIf { it > 0 } ?: width
            val srcH = drawable.intrinsicHeight.takeIf { it > 0 } ?: height

            val scale = max(width / srcW.toFloat(), height / srcH.toFloat())
            val dx = (width - srcW * scale) / 2f
            val dy = (height - srcH * scale) / 2f

            drawable.bounds = Rect(0, 0, srcW, srcH)

            val saved = canvas.save()
            canvas.translate(dx, dy)
            canvas.scale(scale, scale)
            drawable.draw(canvas)
            canvas.restoreToCount(saved)
        }
    }
}
