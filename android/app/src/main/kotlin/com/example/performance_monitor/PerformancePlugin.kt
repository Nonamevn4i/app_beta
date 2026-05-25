package com.example.performance_monitor

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class PerformancePlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "performance_monitor")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "getPerformanceData") {
            val data = getPerformanceData()
            result.success(data)
        } else {
            result.notImplemented()
        }
    }

    private fun getPerformanceData(): Map<String, Any> {
        val memoryInfo = Runtime.getRuntime()
        val totalMemory = memoryInfo.totalMemory()
        val freeMemory = memoryInfo.freeMemory()
        val usedMemory = totalMemory - freeMemory

        val data = HashMap<String, Any>()
        data["totalMemory"] = totalMemory
        data["usedMemory"] = usedMemory
        data["freeMemory"] = freeMemory
        return data
    }

    override fun onDetachedFromEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
