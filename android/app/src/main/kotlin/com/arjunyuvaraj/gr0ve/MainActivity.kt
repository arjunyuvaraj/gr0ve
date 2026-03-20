package com.arjunyuvaraj.gr0ve

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val ICON_CHANNEL = "com.gr0ve.app/icon"

    private val baseActivity = "MainActivity"
    private val allAliases = listOf(
        "MainActivityGrover",
        "MainActivityAspen",
        "MainActivityRowan",
        "MainActivitySakura",
        "MainActivityAbies",
        "MainActivityCedite",
    )

    private var pendingAlias: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // ── Icon channel ─────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ICON_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setIcon" -> {
                        val alias = call.argument<String>("alias")
                        if (alias == null) {
                            result.error("INVALID_ARG", "alias must not be null", null)
                            return@setMethodCallHandler
                        }
                        pendingAlias = alias
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Defer icon switch to when app is backgrounded (prevents Android
    // killing the foreground process mid-interaction)
    override fun onStop() {
        super.onStop()
        pendingAlias?.let { alias ->
            pendingAlias = null
            try { applyIconSwitch(alias) } catch (_: Exception) {}
        }
    }

    private fun applyIconSwitch(targetAlias: String) {
        val pm = packageManager
        pm.setComponentEnabledSetting(
            ComponentName(this, "${packageName}.$baseActivity"),
            PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
            PackageManager.DONT_KILL_APP,
        )
        allAliases.forEach { alias ->
            pm.setComponentEnabledSetting(
                ComponentName(this, "${packageName}.$alias"),
                if (alias == targetAlias)
                    PackageManager.COMPONENT_ENABLED_STATE_ENABLED
                else
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }
}