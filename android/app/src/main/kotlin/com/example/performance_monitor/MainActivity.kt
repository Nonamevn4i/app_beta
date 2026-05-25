package com.example.performance_monitor

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.performance_monitor/telemetry"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTelemetry" -> {
                    val telemetry = PerformancePlugin.getTelemetry(this)
                    result.success(telemetry)
                }
                "getCpuCores" -> {
                    val cores = PerformancePlugin.getCpuCoreDetails()
                    result.success(cores)
                }
                "getNetworkStats" -> {
                    val stats = PerformancePlugin.getNetworkStats()
                    result.success(stats)
                }
                "getBatteryInfo" -> {
                    val battery = PerformancePlugin.getBatteryInfo(this)
                    result.success(battery)
                }
                else -> result.notImplemented()
            }
        }
    }
}
