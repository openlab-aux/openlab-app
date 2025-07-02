package de.openlab.openlabflutter

import android.app.ActivityManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.widget.RemoteViews

class DoorWidgetProvider : AppWidgetProvider() {
    companion object {
        const val ACTION_BUZZ_INNER = "ACTION_BUZZ_INNER"
        const val ACTION_BUZZ_OUTER = "ACTION_BUZZ_OUTER"
        const val EXTRA_WIDGET_ID = "EXTRA_WIDGET_ID"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(
        context: Context,
        intent: Intent,
    ) {
        super.onReceive(context, intent)

        if (!isAppRunning(context)) {
            // Launch the app
            val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            launchIntent?.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(launchIntent)

            Handler(Looper.getMainLooper()).postDelayed({
                startBuzz(intent, context)
            }, 2000)
        } else {
            startBuzz(intent, context)
        }
    }

    private fun startBuzz(
        intent: Intent,
        context: Context,
    ) {
        when (intent.action) {
            ACTION_BUZZ_INNER -> {
                buzz("inner", context)
            }
            ACTION_BUZZ_OUTER -> {
                buzz("outer", context)
            }
        }
    }

    private fun buzz(
        type: String,
        context: Context,
    ) {
        val flutterIntent =
            Intent(context, MainActivity::class.java).apply {
                putExtra("buzz_type", type)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
            }
        context.startActivity(flutterIntent)
    }

    private fun isAppRunning(context: Context): Boolean {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val runningApps = activityManager.runningAppProcesses
        return runningApps?.any { processInfo -> processInfo.processName == context.packageName } == true
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
    ) {
        val views = RemoteViews(context.packageName, R.layout.door_widget)

        // Setup inner door button
        val innerIntent =
            Intent(context, DoorWidgetProvider::class.java).apply {
                action = ACTION_BUZZ_INNER
                putExtra(EXTRA_WIDGET_ID, appWidgetId)
            }
        val innerPendingIntent =
            PendingIntent.getBroadcast(
                context,
                appWidgetId * 2,
                innerIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        views.setOnClickPendingIntent(R.id.btn_inner_door, innerPendingIntent)

        // Setup outer door button
        val outerIntent =
            Intent(context, DoorWidgetProvider::class.java).apply {
                action = ACTION_BUZZ_OUTER
                putExtra(EXTRA_WIDGET_ID, appWidgetId)
            }
        val outerPendingIntent =
            PendingIntent.getBroadcast(
                context,
                appWidgetId * 2 + 1,
                outerIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        views.setOnClickPendingIntent(R.id.btn_outer_door, outerPendingIntent)

        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
