package com.shibu.app.wallpaper

import android.app.WallpaperManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.os.Build
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
 * A live wallpaper that paints the current kanji card over the user's chosen
 * photo.
 *
 * Android phones have no public API for third-party lock screen widgets, so the
 * wallpaper is how Shibu reaches the lock screen at all: the system draws the
 * same wallpaper surface behind both the lock screen and the home screen, which
 * means one implementation covers both.
 *
 * Drawing is entirely on demand. The engine repaints when it becomes visible,
 * when the surface changes size, and when the card rotates — never on a timer.
 */
class ShibuWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = CardEngine()

    private inner class CardEngine : Engine() {

        private var visible = false
        private var background: Bitmap? = null
        private var backgroundToken: String? = null
        private var surfaceWidth = 0
        private var surfaceHeight = 0

        private val dimPaint = Paint()
        private val bitmapPaint = Paint(Paint.FILTER_BITMAP_FLAG or Paint.ANTI_ALIAS_FLAG)

        /** Fires when the card rotates or the user changes a setting. */
        private val cardChanged = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                // A settings change can swap the background image too.
                if (intent.getBooleanExtra(EXTRA_RELOAD_BACKGROUND, false)) {
                    releaseBackground()
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
            releaseBackground()
            super.onDestroy()
        }

        override fun onVisibilityChanged(visible: Boolean) {
            this.visible = visible
            if (!visible) return

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
                releaseBackground()
            }
            drawFrame()
        }

        override fun onSurfaceDestroyed(holder: SurfaceHolder) {
            visible = false
            releaseBackground()
            super.onSurfaceDestroyed(holder)
        }

        private fun drawFrame() {
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
        }

        private fun render(canvas: Canvas) {
            val context = applicationContext
            val prefs = Prefs(context)

            drawBackground(canvas, prefs)

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

        private fun drawBackground(canvas: Canvas, prefs: Prefs) {
            val bitmap = obtainBackground(prefs)
            if (bitmap == null) {
                canvas.drawColor(prefs.wallpaperColor)
            } else {
                canvas.drawBitmap(bitmap, 0f, 0f, bitmapPaint)
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
         * Loads and centre-crops the chosen photo to the surface, caching the
         * result. The token guards against silently reusing a stale bitmap
         * after the user picks a different image.
         */
        private fun obtainBackground(prefs: Prefs): Bitmap? {
            val path = prefs.wallpaperPath ?: return null
            val file = File(path)
            if (!file.exists()) return null

            val token = "$path:${file.lastModified()}:${surfaceWidth}x$surfaceHeight"
            background?.let { if (token == backgroundToken) return it }

            releaseBackground()
            val loaded = decodeCentreCropped(file) ?: return null
            background = loaded
            backgroundToken = token
            return loaded
        }

        private fun decodeCentreCropped(file: File): Bitmap? = try {
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
                val decoded = BitmapFactory.decodeFile(file.absolutePath, options)
                decoded?.let { centreCrop(it, surfaceWidth, surfaceHeight) }
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
                bitmapPaint,
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

        private fun releaseBackground() {
            background?.recycle()
            background = null
            backgroundToken = null
        }
    }

    companion object {
        private const val TAG = "ShibuWallpaper"

        /** Set on [RotationEngine.ACTION_CARD_CHANGED] when the photo changed. */
        const val EXTRA_RELOAD_BACKGROUND = "reload_background"

        /** Intent that opens the system live wallpaper picker on Shibu. */
        fun pickerIntent(context: Context): Intent =
            Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).putExtra(
                WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                android.content.ComponentName(context, ShibuWallpaperService::class.java),
            )
    }
}
