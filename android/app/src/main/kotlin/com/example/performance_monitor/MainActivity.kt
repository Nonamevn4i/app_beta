package com.example.performance_monitor

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.widget.Toast
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.performance_monitor/telemetry"
    private lateinit var performanceMonitor: PerformanceMonitor
    private var overlayServiceRunning = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        performanceMonitor = PerformanceMonitor(applicationContext)
        performanceMonitor.setWindowForFps(window)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getTelemetry" -> {
                        try {
                            val data = performanceMonitor.getTelemetry()
                            result.success(data)
                        } catch (e: Exception) {
                            result.error("TELEMETRY_ERROR", e.message, null)
                        }
                    }
                    "getCpuCores" -> {
                        try {
                            val cores = performanceMonitor.getCpuCoreDetails()
                            result.success(cores)
                        } catch (e: Exception) {
                            result.error("CPU_ERROR", e.message, null)
                        }
                    }
                    "getNetworkStats" -> {
                        try {
                            val stats = performanceMonitor.getNetworkStats()
                            result.success(stats)
                        } catch (e: Exception) {
                            result.error("NETWORK_ERROR", e.message, null)
                        }
                    }
                    "getBatteryInfo" -> {
                        try {
                            val info = performanceMonitor.getBatteryInfo()
                            result.success(info)
                        } catch (e: Exception) {
                            result.error("BATTERY_ERROR", e.message, null)
                        }
                    }
                    "startOverlayService" -> {
                        if (checkOverlayPermission()) {
                            startOverlayService()
                            result.success(true)
                        } else {
                            requestOverlayPermission()
                            result.success(false)
                        }
                    }
                    "stopOverlayService" -> {
                        stopOverlayService()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun checkOverlayPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else true
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_REQUEST_CODE)
        }
    }

    private fun startOverlayService() {
        val intent = Intent(this, OverlayService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        overlayServiceRunning = true
        Toast.makeText(this, "NEXUS Overlay started", Toast.LENGTH_SHORT).show()
    }

    private fun stopOverlayService() {
        val intent = Intent(this, OverlayService::class.java)
        stopService(intent)
        overlayServiceRunning = false
        Toast.makeText(this, "NEXUS Overlay stopped", Toast.LENGTH_SHORT).show()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == OVERLAY_PERMISSION_REQUEST_CODE) {
            if (checkOverlayPermission()) {
                startOverlayService()
            } else {
                Toast.makeText(this, "Overlay permission is required", Toast.LENGTH_LONG).show()
            }
        }
    }

    override fun onDestroy() {
        performanceMonitor.release()
        super.onDestroy()
    }

    companion object {
        private const val OVERLAY_PERMISSION_REQUEST_CODE = 1001
    }
}
