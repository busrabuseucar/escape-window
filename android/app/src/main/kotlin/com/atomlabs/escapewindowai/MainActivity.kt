package com.atomlabs.escapewindowai

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Process
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "escape_window_ai/usage_stats"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasUsageAccess" -> result.success(hasUsageAccess())
                    "openUsageAccessSettings" -> {
                        startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                        result.success(null)
                    }
                    "queryUsageEvents" -> {
                        if (!hasUsageAccess()) {
                            result.error("USAGE_ACCESS_DENIED", "Usage access is not granted.", null)
                            return@setMethodCallHandler
                        }

                        val startMs = call.argument<Number>("startMs")?.toLong()
                        val endMs = call.argument<Number>("endMs")?.toLong()
                        if (startMs == null || endMs == null || endMs <= startMs) {
                            result.error("INVALID_RANGE", "A valid startMs/endMs range is required.", null)
                            return@setMethodCallHandler
                        }

                        result.success(queryUsageEvents(startMs, endMs))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasUsageAccess(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun queryUsageEvents(startMs: Long, endMs: Long): List<Map<String, Any>> {
        val manager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val usageEvents = manager.queryEvents(startMs, endMs)
        val event = UsageEvents.Event()
        val output = mutableListOf<Map<String, Any>>()

        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                event.eventType == UsageEvents.Event.MOVE_TO_BACKGROUND
            ) {
                output.add(
                    mapOf(
                        "packageName" to event.packageName,
                        "timestampMs" to event.timeStamp,
                        "eventType" to event.eventType
                    )
                )
            }
        }

        return output
    }
}
