package com.example.performance_monitor

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "performance_monitor"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTelemetry" -> {
                    val telemetry = PerformancePlugin.getTelemetry(applicationContext)
                    result.success(telemetry)
                }
                "getCpuCoreDetails" -> {
                    val coreDetails = PerformancePlugin.getCpuCoreDetails()
                    result.success(coreDetails)
                }
                "getNetworkStats" -> {
                    val netStats = PerformancePlugin.getNetworkStats()
                    result.success(netStats)
                }
                "getBatteryInfo" -> {
                    val batteryInfo = PerformancePlugin.getBatteryInfo(applicationContext)
                    result.success(batteryInfo)
                }
                "getRamInfo" -> {
                    val ramInfo = PerformancePlugin.getRamInfo(applicationContext)
                    result.success(ramInfo)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
