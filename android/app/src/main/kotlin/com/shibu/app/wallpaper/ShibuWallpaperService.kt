package com.shibu.app.wallpaper

import android.app.WallpaperManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ImageDecoder
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.AnimatedImageDrawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.service.wallpaper.WallpaperService
import android.util.Log
import android.view.SurfaceHolder
import com.shibu.app.data.KanjiStore
import com.shibu.app.data.Prefs
import com.shibu.app.render.CardRenderer
import com.shibu.app.render.CardStyle
import com.shibu.app.rotation.RotationEngine
import java.io.File
import kotlin.math.max
import kotlin.math.roundToInt

/**
 * A live wallpaper that paints the current kanji card over the chosen backdrop.
 *
 * Android phones have no public API for third-party lock screen widgets, so the
 * wallpaper is how Shibu reaches the lock screen at all: the system draws the
 * same wallpaper surface behind both the lock screen and the home screen, which
 * means one implementation covers both.
 *
 * A still backdrop is drawn on demand — when the engine becomes visible, when
 * the surface resizes, and when the card rotates. An animated backdrop adds a
 * repeating redraw, but only while the wallpaper is actually visible.
 */
class ShibuWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = CardEngine()

    private inner class CardEngine : Engine() {

        private var visible = false
        private var backdrop: Backdrop? = null
        private var backdropToken: String? = null
        private var surfaceWidth = 0
        private var surfaceHeight = 0

        private val dimPaint = Paint()
        private val handler = Handler(Looper.getMainLooper())
        private val animationTick = Runnable { drawFrame() }

        /** Fires when the card rotates or the user changes a setting. */
        private val cardChanged = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                // A settings change can swap the backdrop entirely.
                if (intent.getBooleanExtra(EXTRA_RELOAD_BACKGROUND, false)) {
                    releaseBackdrop()
                }
                drawFrame()
            }
        }

        override fun onCreate(holder: SurfaceHolder) {
            super.onCreate(holder)
            setOffsetNotificationsEnabled(false)
            val filter = IntentFilter(RotationEngine.ACTION_CARD_CHANGED)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(cardChanged, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("UnspecifiedRegisterReceiverFlag")
                registerReceiver(cardChanged, filter)
            }
        }

        override fun onDestroy() {
            runCatching { unregisterReceiver(cardChanged) }
            handler.removeCallbacks(animationTick)
            releaseBackdrop()
            super.onDestroy()
        }

        override fun onVisibilityChanged(visible: Boolean) {
            this.visible = visible
            if (!visible) {
                // Nothing on screen: stop burning battery on animation frames.
                handler.removeCallbacks(animationTick)
                return
            }

            // Becoming visible means the lock screen or home screen just came
            // up, which is exactly the "show me a new one" moment. If nothing
            // is due, maybeRotate is a no-op and we still repaint below.
            val rotated = RotationEngine.maybeRotate(
                applicationContext,
                RotationEngine.Trigger.SCREEN_VISIBLE,
            )
            if (!rotated) drawFrame()
        }

        override fun onSurfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            super.onSurfaceChanged(holder, format, width, height)
            if (width != surfaceWidth || height != surfaceHeight) {
                surfaceWidth = width
                surfaceHeight = height
                releaseBackdrop()
            }
            drawFrame()
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            visible = false
            handler.removeCallbacks(animationTick)
            releaseBackdrop()
            super.onSurfaceDestroyed(holder)
        }

        private fun drawFrame() {
            handler.removeCallbacks(animationTick)
            if (!visible || surfaceWidth == 0 || surfaceHeight == 0) return

            val holder = surfaceHolder
            var canvas: Canvas? = null
            try {
                canvas = holder.lockCanvas()
                if (canvas != null) render(canvas)
            } catch (e: Exception) {
                Log.e(TAG, "could not draw wallpaper frame", e)
            } finally {
                if (canvas != null) {
                    runCatching { holder.unlockCanvasAndPost(canvas) }
                }
            }

            // Schedule the next frame only for a moving backdrop. Capping at
            // FRAME_INTERVAL_MS rather than chasing the source frame rate keeps
            // a 60fps GIF from pinning the CPU behind the lock screen.
            if (visible && backdrop?.isAnimated == true) {
                handler.postDelayed(animationTick, FRAME_INTERVAL_MS)
            }
        }

        private fun render(canvas: Canvas) {
            val context = applicationContext
            val prefs = Prefs(context)

            drawBackdrop(canvas, prefs)

            val kanji = KanjiStore.current(context) ?: return
            val style = CardStyle.forWallpaper(context)

            val insetX = (surfaceWidth * prefs.offsetX).roundToInt()
            val maxWidth = surfaceWidth - insetX * 2
            if (maxWidth <= 0) return

            val card = CardRenderer.layout(context, kanji, style, maxWidth)

            val left = when (style.align) {
                CardStyle.Align.CENTER -> (surfaceWidth - card.width) / 2f
                CardStyle.Align.RIGHT -> (surfaceWidth - insetX - card.width).toFloat()
                CardStyle.Align.LEFT -> insetX.toFloat()
            }
            val top = (surfaceHeight * prefs.offsetY) - card.height / 2f

            card.draw(canvas, left, top.coerceIn(0f, (surfaceHeight - card.height).toFloat()))
        }

        private fun drawBackdrop(canvas: Canvas, prefs: Prefs) {
            val current = obtainBackdrop(prefs)
            if (current == null) {
                canvas.drawColor(prefs.wallpaperColor)
            } else {
                current.draw(canvas, surfaceWidth, surfaceHeight)
            }

            val dim = prefs.wallpaperDim
            if (dim > 0f) {
                dimPaint.color = Color.argb((dim * 255).roundToInt(), 0, 0, 0)
                canvas.drawRect(
                    RectF(0f, 0f, surfaceWidth.toFloat(), surfaceHeight.toFloat()),
                    dimPaint,
                )
            }
        }

        /**
         * Builds the backdrop for the current settings, caching it. The token
         * guards against silently reusing a stale one after the user picks a
         * different image or preset.
         */
        private fun obtainBackdrop(prefs: Prefs): Backdrop? {
            val token = backdropToken(prefs)
            backdrop?.let { if (token == backdropToken) return it }

            releaseBackdrop()
            val built = buildBackdrop(prefs) ?: return null
            backdrop = built
            backdropToken = token
            return built
        }

        private fun backdropToken(prefs: Prefs): String {
            if (prefs.backgroundKind != Prefs.BACKGROUND_IMAGE) {
                return "preset:${prefs.backgroundPreset}:${surfaceWidth}x$surfaceHeight"
            }
            val path = prefs.wallpaperPath ?: return "none"
            val stamp = File(path).let { if (it.exists()) it.lastModified() else 0L }
            return "image:$path:$stamp:${prefs.backgroundAnimate}:${surfaceWidth}x$surfaceHeight"
        }

        private fun buildBackdrop(prefs: Prefs): Backdrop? {
            if (prefs.backgroundKind != Prefs.BACKGROUND_IMAGE) {
                return Backdrop.Gradient(prefs.backgroundPreset)
            }

            val path = prefs.wallpaperPath ?: return Backdrop.Gradient(prefs.backgroundPreset)
            val file = File(path)
            if (!file.exists()) return Backdrop.Gradient(prefs.backgroundPreset)

            return decodeAnimated(file, prefs.backgroundAnimate)
                ?: decodeStill(file)
                ?: Backdrop.Gradient(prefs.backgroundPreset)
        }

        /**
         * Decodes a GIF or animated WebP.
         *
         * Returns null when the file is not animated, or on API levels without
         * [ImageDecoder], so the caller can fall back to a still decode.
         */
        private fun decodeAnimated(file: File, animate: Boolean): Backdrop? {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return null
            return try {
                val source = ImageDecoder.createSource(file)
                val drawable = ImageDecoder.decodeDrawable(source) { decoder, info, _ ->
                    // Decode straight to the surface size: a full-resolution
                    // animated image would hold every frame at source size.
                    val scale = max(
                        surfaceWidth / info.size.width.toFloat(),
                        surfaceHeight / info.size.height.toFloat(),
                    ).coerceAtMost(1f)
                    if (scale < 1f) {
                        decoder.setTargetSize(
                            (info.size.width * scale).roundToInt().coerceAtLeast(1),
                            (info.size.height * scale).roundToInt().coerceAtLeast(1),
                        )
                    }
                    decoder.allocator = ImageDecoder.ALLOCATOR_SOFTWARE
                }
                (drawable as? AnimatedImageDrawable)?.let { Backdrop.Animated(it, animate) }
            } catch (e: Exception) {
                Log.w(TAG, "could not decode animated background", e)
                null
            }
        }

        private fun decodeStill(file: File): Backdrop? = try {
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(file.absolutePath, bounds)

            if (bounds.outWidth <= 0 || bounds.outHeight <= 0) {
                null
            } else {
                val options = BitmapFactory.Options().apply {
                    inSampleSize = sampleSize(
                        bounds.outWidth, bounds.outHeight, surfaceWidth, surfaceHeight,
                    )
                    inPreferredConfig = Bitmap.Config.ARGB_8888
                }
                BitmapFactory.decodeFile(file.absolutePath, options)
                    ?.let { Backdrop.Still(centreCrop(it, surfaceWidth, surfaceHeight)) }
            }
        } catch (e: OutOfMemoryError) {
            Log.e(TAG, "background image too large to decode", e)
            null
        } catch (e: Exception) {
            Log.e(TAG, "could not decode background image", e)
            null
        }

        private fun centreCrop(source: Bitmap, width: Int, height: Int): Bitmap {
            if (source.width == width && source.height == height) return source

            val scale = max(width / source.width.toFloat(), height / source.height.toFloat())
            val scaledWidth = source.width * scale
            val scaledHeight = source.height * scale
            val dx = (width - scaledWidth) / 2f
            val dy = (height - scaledHeight) / 2f

            val output = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            Canvas(output).drawBitmap(
                source,
                Rect(0, 0, source.width, source.height),
                RectF(dx, dy, dx + scaledWidth, dy + scaledHeight),
                Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG),
            )
            if (source != output) source.recycle()
            return output
        }

        private fun sampleSize(srcW: Int, srcH: Int, dstW: Int, dstH: Int): Int {
            if (dstW <= 0 || dstH <= 0) return 1
            var sample = 1
            while (srcW / (sample * 2) >= dstW && srcH / (sample * 2) >= dstH) {
                sample *= 2
            }
            return sample
        }

        private fun releaseBackdrop() {
            backdrop?.release()
            backdrop = null
            backdropToken = null
        }
    }

    companion object {
        private const val TAG = "ShibuWallpaper"

        /** ~20fps. Fast enough to read as motion, slow enough to be polite. */
        private const val FRAME_INTERVAL_MS = 50L

        /** Set on [RotationEngine.ACTION_CARD_CHANGED] when the backdrop changed. */
        const val EXTRA_RELOAD_BACKGROUND = "reload_background"

        /** Intent that opens the system live wallpaper picker on Shibu. */
        fun pickerIntent(context: Context): Intent =
            Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).putExtra(
                WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                ComponentName(context, ShibuWallpaperService::class.java),
            )
    }
}
