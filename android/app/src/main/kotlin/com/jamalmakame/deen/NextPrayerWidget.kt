package com.jamalmakame.deen

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.text.format.DateFormat
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import java.util.Date

/** Shows the next prayer from the times the app saved (see prayer_widget.dart). */
class NextPrayerWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val now = System.currentTimeMillis()
        var line = "—"
        try {
            val list = JSONArray(widgetData.getString("prayers", "[]"))
            for (i in 0 until list.length()) {
                val item = list.getJSONArray(i)
                val at = item.getLong(0)
                if (at > now) {
                    val time = DateFormat.getTimeFormat(context).format(Date(at))
                    line = "${item.getString(1)} · $time"
                    break
                }
            }
        } catch (_: Exception) {
        }
        val open = PendingIntent.getActivity(
            context,
            0,
            Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.next_prayer_widget).apply {
                setTextViewText(R.id.widget_label, widgetData.getString("label", "Deen"))
                setTextViewText(R.id.widget_prayer, line)
                setTextViewText(R.id.widget_city, widgetData.getString("city", ""))
                setOnClickPendingIntent(R.id.widget_root, open)
            }
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
