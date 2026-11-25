package com.sanketa.sanketa_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class SanketaWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val ACTION_POWER = "com.sanketa.action.POWER"
        private const val ACTION_VOL_UP = "com.sanketa.action.VOL_UP"
        private const val ACTION_VOL_DOWN = "com.sanketa.action.VOL_DOWN"
        private const val ACTION_MUTE = "com.sanketa.action.MUTE"
        private const val ACTION_HOME = "com.sanketa.action.HOME"
        private const val ACTION_OPEN_APP = "com.sanketa.action.OPEN_APP"
    }

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) {
            val views = RemoteViews(context.packageName, R.layout.widget_remote)
            views.setOnClickPendingIntent(R.id.btn_power, makePendingIntent(context, ACTION_POWER))
            views.setOnClickPendingIntent(R.id.btn_vol_up, makePendingIntent(context, ACTION_VOL_UP))
            views.setOnClickPendingIntent(R.id.btn_vol_down, makePendingIntent(context, ACTION_VOL_DOWN))
            views.setOnClickPendingIntent(R.id.btn_mute, makePendingIntent(context, ACTION_MUTE))
            views.setOnClickPendingIntent(R.id.btn_home, makePendingIntent(context, ACTION_HOME))
            views.setOnClickPendingIntent(R.id.btn_open, makePendingIntent(context, ACTION_OPEN_APP))
            manager.updateAppWidget(id, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action ?: return
        if (action in listOf(ACTION_POWER, ACTION_VOL_UP, ACTION_VOL_DOWN, ACTION_MUTE, ACTION_HOME)) {
            val launch = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("widget_command", action.removePrefix("com.sanketa.action."))
            }
            context.startActivity(launch)
        } else if (action == ACTION_OPEN_APP) {
            val launch = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            context.startActivity(launch)
        }
    }

    private fun makePendingIntent(context: Context, action: String): PendingIntent {
        val intent = Intent(context, SanketaWidgetProvider::class.java).apply {
            this.action = action
        }
        return PendingIntent.getBroadcast(
            context, action.hashCode(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
