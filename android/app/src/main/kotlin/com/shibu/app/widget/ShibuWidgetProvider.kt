package com.shibu.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.os.Bundle
import android.util.Log
import android.util.TypedValue
import android.widget.RemoteViews
import com.shibu.app.MainActivity
import com.shibu.app.R
import com.shibu.app.data.KanjiStore
import com.shibu.app.data.Prefs
import com.shibu.app.render.CardRenderer
import com.shibu.app.render.CardStyle
import com.shibu.app.rotation.RotationEngine
import com.shibu.app.rotation.Scheduler
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * The home screen widget.
 *
 * The card is rendered to a bitmap with the same [CardRenderer] the wallpaper
 * uses, so the two surfaces cannot drift apart visually. The widget's rounded
 * background is a plain drawable rather than part of the bitmap, which keeps
 * the bitmap small — RemoteViews are delivered over Binder, and an oversized
 * bitmap silently fails to appear.
 */
class ShibuWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        // A widget being added is a good moment to make sure the heartbeat that
        // drives interval rotation is actually running.
        Scheduler.ensureScheduled(context)
        RotationEngine.maybeRotate(context, RotationEngine.Trigger.PERIODIC)

        appWidgetIds.forEach { render(context, appWidgetManager, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        // The user resized the widget, so the card needs laying out again.
        render(context, appWidgetManager, appWidgetId)
    }

    override fun onDisabled(context: Context) {
        // Nothing left to feed. The wallpaper, if active, re-arms this itself.
        if (!hasLiveWallpaper(context)) Scheduler.cancel(context)
    }

    companion object {
        private const val TAG = "ShibuWidget"

        /** Padding inside the widget frame, in dp. */
        private const val PADDING_DP = 14f

        /**
         * Ceiling on the rendered bitmap. RemoteViews travel through a ~1 MB
         * Binder transaction, so a full-resolution card on a large display
         * would be dropped without warning.
         */
        private const val MAX_PIXELS = 220_000

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, ShibuWidgetProvider::class.java)
            )
            ids.forEach { render(context, manager, it) }
        }

        private fun render(context: Context, manager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.widget_card)
                val prefs = Prefs(context)

                views.setInt(
                    R.id.widget_root,
                    "setBackgroundResource",
                    backgroundResource(prefs.widgetBackground),
                )

                val kanji = KanjiStore.current(context)
                if (kanji == null) {
                    views.setViewVisibility(R.id.widget_card_image, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_empty, android.view.View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_empty, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_card_image, android.view.View.VISIBLE)
                    views.setImageViewBitmap(
                        R.id.widget_card_image,
                        renderCard(context, manager, appWidgetId, kanji.id),
                    )
                }

                views.setOnClickPendingIntent(R.id.widget_root, openAppIntent(context))
                manager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.e(TAG, "could not render widget $appWidgetId", e)
            }
        }

        private fun renderCard(
            context: Context,
            manager: AppWidgetManager,
            appWidgetId: Int,
            kanjiId: Int,
        ): Bitmap {
            val metrics = context.resources.displayMetrics
            val padding = TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP, PADDING_DP, metrics,
            )

            val options = manager.getAppWidgetOptions(appWidgetId)
            val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250)
            val widthPx = TypedValue.applyDimension(
                TypedValue.COMPLEX_UNIT_DIP, widthDp.toFloat(), metrics,
            ).roundToInt()

            val available = (widthPx - padding * 2).roundToInt().coerceAtLeast(1)

            val kanji = KanjiStore.byId(context, kanjiId)
                ?: KanjiStore.all(context).first()
            val card = CardRenderer.layout(context, kanji, CardStyle.forWidget(context), available)

            val bitmap = card.toBitmap()
            return downscaleIfNeeded(bitmap)
        }

        /** Shrinks a bitmap that would blow the RemoteViews transaction budget. */
        private fun downscaleIfNeeded(bitmap: Bitmap): Bitmap {
            val pixels = bitmap.width.toLong() * bitmap.height
            if (pixels <= MAX_PIXELS) return bitmap

            val factor = sqrt(MAX_PIXELS.toDouble() / pixels).toFloat()
            val scaled = Bitmap.createScaledBitmap(
                bitmap,
                (bitmap.width * factor).roundToInt().coerceAtLeast(1),
                (bitmap.height * factor).roundToInt().coerceAtLeast(1),
                true,
            )
            if (scaled != bitmap) bitmap.recycle()
            return scaled
        }

        private fun backgroundResource(mode: String): Int = when (mode) {
            Prefs.WIDGET_BG_TRANSPARENT -> R.drawable.widget_bg_transparent
            Prefs.WIDGET_BG_SOLID -> R.drawable.widget_bg_solid
            else -> R.drawable.widget_bg_scrim
        }

        private fun openAppIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java)
                .setAction(Intent.ACTION_MAIN)
                .addCategory(Intent.CATEGORY_LAUNCHER)
                .setFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            return PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun hasLiveWallpaper(context: Context): Boolean = runCatching {
            val info = android.app.WallpaperManager.getInstance(context).wallpaperInfo
            info?.packageName == context.packageName
        }.getOrDefault(false)
    }
}
