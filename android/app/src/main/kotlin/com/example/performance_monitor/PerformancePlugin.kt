package com.example.performance_monitor

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.app.ActivityManager
import android.net.TrafficStats
import android.os.Process
import java.io.BufferedReader
import java.io.FileReader
import java.io.RandomAccessFile
import java.net.InetAddress
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

// =================================================================
// 1. LỚP BỌC FLUTTER PLUGIN ĐỂ NHẬN LỆNH TỪ FLUTTER (NẾU CÓ)
// =================================================================
class PerformanceMonitorPlugin: FlutterPlugin, MethodCallHandler {
    private lateinit var channel : MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "performance_monitor")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getTelemetry" -> result.success(PerformancePlugin.getTelemetry(context))
            "getCpuCoreDetails" -> result.success(PerformancePlugin.getCpuCoreDetails())
            "getNetworkStats" -> result.success(PerformancePlugin.getNetworkStats())
            "getBatteryInfo" -> result.success(PerformancePlugin.getBatteryInfo(context))
            "getRamInfo" -> result.success(PerformancePlugin.getRamInfo(context))
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

// =================================================================
// 2. OBJECT TÍNH NĂNG GỐC - ĐÃ VÁ LỖI KIỂU DỮ LIỆU & BIẾN
// =================================================================
object PerformancePlugin {

    // Thay đổi kiểu Map thành Any? để sửa triệt để lỗi Return type mismatch
    fun getTelemetry(context: Context): Map<String, Any?> {
        val cpuInfo = getCpuUsage()
        val gpuInfo = getGpuInfo()
        val temps = getTemperatures()
        val battery = getBatteryInfo(context)
        val ram = getRamInfo(context)

        return mapOf(
            "fps" to 0,
            "cpuUsage" to cpuInfo["usage"],
            "cpuFreq" to cpuInfo["freqMax"],
            "cpuTemp" to temps["cpuTemp"],
            "gpuUsage" to gpuInfo["usage"],
            "gpuFreq" to gpuInfo["freq"],
            "gpuTemp" to temps["gpuTemp"],
            "batteryTemp" to battery["temperature"],
            "batteryLevel" to battery["level"],
            "ramUsage" to ram["usage"],
            "ramTotal" to ram["total"],
            "throttleStatus" to getThrottleStatus(
                (temps["cpuTemp"] as? Double)?.toInt() ?: 0,
                (temps["gpuTemp"] as? Double)?.toInt() ?: 0
            )
        )
    }

    fun getCpuCoreDetails(): List<Map<String, Any>> {
        val cores = mutableListOf<Map<String, Any>>()
        val numCores = Runtime.getRuntime().availableProcessors()
        for (i in 0 until numCores) {
            val freq = try {
                BufferedReader(FileReader("/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq"))
                    .use { it.readLine()?.toLong()?.div(1000) ?: 0 }
            } catch (e: Exception) { 0L }
            cores.add(mapOf(
                "core" to i,
                "frequency" to freq,
                "maxFrequency" to getMaxFreq(i),
                "minFrequency" to getMinFreq(i),
                "governor" to getGovernor(i)
            ))
        }
        return cores
    }

    private fun getMaxFreq(core: Int): Long = try {
        BufferedReader(FileReader("/sys/devices/system/cpu/cpu$core/cpufreq/cpuinfo_max_freq"))
            .use { it.readLine()?.toLong()?.div(1000) ?: 0L }
    } catch (e: Exception) { 0L }

    private fun getMinFreq(core: Int): Long = try {
        BufferedReader(FileReader("/sys/devices/system/cpu/cpu$core/cpufreq/cpuinfo_min_freq"))
            .use { it.readLine()?.toLong()?.div(1000) ?: 0L }
    } catch (e: Exception) { 0L }

    private fun getGovernor(core: Int): String = try {
        BufferedReader(FileReader("/sys/devices/system/cpu/cpu$core/cpufreq/scaling_governor"))
            .use { it.readLine() ?: "unknown" }
    } catch (e: Exception) { "unknown" }

    private var previousCpuTimes: LongArray? = null
    private var previousTotalTime: Long = 0

    private fun getCpuUsage(): Map<String, Any> {
        return try {
            val statFile = RandomAccessFile("/proc/stat", "r")
            val cpuLine = statFile.readLine() ?: return mapOf("usage" to 0.0, "freqMax" to 0.0)
            statFile.close()
            val parts = cpuLine.split("\\s+".toRegex())
            if (parts.size < 5) return mapOf("usage" to 0.0, "freqMax" to 0.0)
            val user = parts[1].toLong()
            val nice = parts[2].toLong()
            val system = parts[3].toLong()
            val idle = parts[4].toLong()
            val totalTime = user + nice + system + idle
            val currentCpuTimes = longArrayOf(user, nice, system, idle)
            if (previousCpuTimes == null) {
                previousCpuTimes = currentCpuTimes
                previousTotalTime = totalTime
                return mapOf("usage" to 0.0, "freqMax" to getMaxCpuFreq())
            }
            val totalDelta = (totalTime - previousTotalTime).toDouble()
            val idleDelta = (idle - (previousCpuTimes?.get(3) ?: 0)).toDouble()
            val usagePercent = if (totalDelta > 0) ((totalDelta - idleDelta) / totalDelta) * 100.0 else 0.0
            previousCpuTimes = currentCpuTimes
            previousTotalTime = totalTime
            mapOf("usage" to usagePercent, "freqMax" to getMaxCpuFreq())
        } catch (e: Exception) {
            mapOf("usage" to 0.0, "freqMax" to 0.0)
        }
    }

    private var previousGpuTimes: LongArray? = null
    private var previousGpuTotal: Long = 0

    private fun getGpuInfo(): Map<String, Any> {
        val freq = try {
            BufferedReader(FileReader("/sys/class/kgsl/kgsl-3d0/devfreq/cur_freq"))
                .use { it.readLine()?.toLong()?.div(1000000) ?: 0L }
        } catch (e: Exception) { 0L }
        return try {
            val gpuFile = RandomAccessFile("/sys/class/kgsl/kgsl-3d0/gpubusy", "r")
            val line = gpuFile.readLine() ?: return mapOf("usage" to 0.0, "freq" to freq.toDouble())
            gpuFile.close()
            val parts = line.split("\\s+".toRegex())
            if (parts.size < 2) return mapOf("usage" to 0.0, "freq" to freq.toDouble())
            val busy = parts[0].toLong()
            val total = parts[1].toLong()
            if (previousGpuTimes != null && (total - previousGpuTotal) > 0) {
                val usagePct = ((busy - (previousGpuTimes?.get(0) ?: 0)).toDouble() / (total - previousGpuTotal).toDouble()) * 100.0
                previousGpuTimes = longArrayOf(busy, total)
                previousGpuTotal = total
                return mapOf("usage" to usagePct, "freq" to freq.toDouble())
            }
            previousGpuTimes = longArrayOf(busy, total)
            previousGpuTotal = total
            mapOf("usage" to 0.0, "freq" to freq.toDouble())
        } catch (e: Exception) {
            mapOf("usage" to 0.0, "freq" to freq.toDouble())
        }
    }

    private fun getTemperatures(): Map<String, Any> {
        var cpuTemp = 0.0
        var gpuTemp = 0.0
        try {
            val cpuTherm = BufferedReader(FileReader("/sys/class/thermal/thermal_zone0/temp"))
                .use { it.readLine()?.toDouble()?.div(1000.0) ?: 0.0 }
            cpuTemp = cpuTherm
        } catch (e: Exception) {
            try {
                cpuTemp = BufferedReader(FileReader("/sys/class/thermal/thermal_zone1/temp"))
                    .use { it.readLine()?.toDouble()?.div(1000.0) ?: 0.0 }
            } catch (e2: Exception) { cpuTemp = 0.0 }
        }
        try {
            gpuTemp = BufferedReader(FileReader("/sys/class/kgsl/kgsl-3d0/temp"))
                .use { it.readLine()?.toDouble()?.div(1000.0) ?: 0.0 }
        } catch (e: Exception) { gpuTemp = 0.0 }
        return mapOf("cpuTemp" to cpuTemp, "gpuTemp" to gpuTemp)
    }

    private fun getMaxCpuFreq(): Double {
        return try {
            (0 until Runtime.getRuntime().availableProcessors()).maxOfOrNull { i ->
                try {
                    BufferedReader(FileReader("/sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq"))
                        .use { it.readLine()?.toLong() ?: 0L }
                } catch (e: Exception) { 0L }
            }?.toDouble()?.div(1000.0) ?: 0.0
        } catch (e: Exception) { 0.0 }
    }

    private var lastRxBytes: Long = TrafficStats.getTotalRxBytes()
    private var lastTxBytes: Long = TrafficStats.getTotalTxBytes()
    private var lastNetTime: Long = System.currentTimeMillis()

    fun getNetworkStats(): Map<String, Any> {
        val currentRx = TrafficStats.getTotalRxBytes()
        val currentTx = TrafficStats.getTotalTxBytes()
        val currentTime = System.currentTimeMillis()
        val timeDelta = (currentTime - lastNetTime) / 1000.0
        var downloadSpeed = 0.0
        var uploadSpeed = 0.0
        if (timeDelta > 0) {
            downloadSpeed = Math.max(0.0, ((currentRx - lastRxBytes) / timeDelta) / (1024 * 1024))
            uploadSpeed = Math.max(0.0, ((currentTx - lastTxBytes) / timeDelta) / (1024 * 1024))
        }
        var ping = 0.0
        try {
            val start = System.currentTimeMillis()
            val reachable = InetAddress.getByName("8.8.8.8").isReachable(2000)
            if (reachable) {
                ping = (System.currentTimeMillis() - start).toDouble()
            }
        } catch (e: Exception) { ping = -1.0 }
        lastRxBytes = currentRx
        lastTxBytes = currentTx
        lastNetTime = currentTime
        return mapOf(
            "downloadSpeed" to downloadSpeed,
            "uploadSpeed" to uploadSpeed,
            "ping" to ping,
            "totalRx" to currentRx,
            "totalTx" to currentTx
        )
    }

    fun getBatteryInfo(context: Context): Map<String, Any> {
        val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus = context.registerReceiver(null, intentFilter)
        val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: 0
        val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: 100
        val temperature = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        val voltage = batteryStatus?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0
        val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: 0
        val plugged = batteryStatus?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0
        val batteryPct = if (scale > 0) (level * 100.0 / scale) else 0.0
        val batteryTempC = temperature / 10.0
        val charging = plugged != 0
        val statusStr = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "Charging"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "Discharging"
            BatteryManager.BATTERY_STATUS_FULL -> "Full"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Not Charging"
            else -> "Unknown"
        }
        return mapOf(
            "level" to batteryPct,
            "temperature" to batteryTempC,
            "voltage" to voltage,
            "status" to statusStr,
            "charging" to charging,
            "health" to getBatteryHealth(batteryStatus?.getIntExtra(BatteryManager.EXTRA_HEALTH, 0) ?: 0)
        )
    }

    private fun getBatteryHealth(health: Int): String = when (health) {
        BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
        BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
        BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
        BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
        BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Failure"
        else -> "Unknown"
    }

    // Đổi từ private fun sang fun để MainActivity.kt có thể truy cập được dữ liệu RAM công khai
    fun getRamInfo(context: Context): Map<String, Any> {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        val totalRam = memoryInfo.totalMem / (1024.0 * 1024 * 1024)
        val availableRam = memoryInfo.availMem / (1024.0 * 1024 * 1024)
        val usedRam = totalRam - availableRam
        return mapOf("usage" to usedRam, "total" to totalRam)
    }

    private fun getThrottleStatus(cpuTemp: Int, gpuTemp: Int): String {
        val maxTemp = maxOf(cpuTemp, gpuTemp)
        return when {
            maxTemp > 85 -> "Critical"
            maxTemp > 72 -> "Warning"
            else -> "Normal"
        }
    }
}
