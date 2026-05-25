package com.example.performance_monitor

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.TrafficStats
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.view.FrameMetrics
import android.view.Window
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.net.InetAddress

class PerformanceMonitor(private val context: Context) {

    // CPU tracking
    private var lastCpuTotal = 0L
    private var lastCpuIdle = 0L
    private var currentCpuUsage = 0.0

    // Per-core tracking
    private var lastCoreTotals = LongArray(0)
    private var lastCoreIdles = LongArray(0)
    private val coreUsages = mutableListOf<Double>()

    // Network tracking
    private var lastRxBytes = TrafficStats.getTotalRxBytes()
    private var lastTxBytes = TrafficStats.getTotalTxBytes()
    private var lastNetTime = System.currentTimeMillis()
    private var downloadSpeed = 0.0
    private var uploadSpeed = 0.0
    private var ping = 0.0

    // FPS tracking via FrameMetrics
    private var frameCount = 0L
    private var lastFpsTime = System.currentTimeMillis()
    private var currentFps = 0

    // FrameMetrics handler thread
    private var frameHandler: Handler? = null

    init {
        val coreCount = Runtime.getRuntime().availableProcessors()
        lastCoreTotals = LongArray(coreCount)
        lastCoreIdles = LongArray(coreCount)
        for (i in 0 until coreCount) {
            coreUsages.add(0.0)
        }

        val thread = HandlerThread("FrameMonitor")
        thread.start()
        frameHandler = Handler(thread.looper)
    }

    fun setWindowForFps(window: Window) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            window.addOnFrameMetricsAvailableListener({ _, _ ->
                frameCount++
                val now = System.currentTimeMillis()
                if (now - lastFpsTime >= 1000) {
                    currentFps = frameCount.toInt()
                    frameCount = 0
                    lastFpsTime = now
                }
            }, frameHandler!!)
        }
    }

    fun setFpsDirect(fps: Int) {
        currentFps = fps
    }

    fun updateAll() {
        updateCpuUsage()
        updatePerCoreCpu()
        updateNetwork()
        updatePing()
    }

    private fun updateCpuUsage() {
        try {
            val reader = BufferedReader(FileReader("/proc/stat"))
            val line = reader.readLine() ?: return
            reader.close()
            val parts = line.split("\\s+".toRegex())
            if (parts.size < 5) return
            val user = parts[1].toLong()
            val nice = parts[2].toLong()
            val sys = parts[3].toLong()
            val idle = parts[4].toLong()
            val iowait = parts.getOrNull(5)?.toLong() ?: 0
            val irq = parts.getOrNull(6)?.toLong() ?: 0
            val softirq = parts.getOrNull(7)?.toLong() ?: 0

            val total = user + nice + sys + idle + iowait + irq + softirq
            val idleAll = idle + iowait

            if (lastCpuTotal > 0) {
                val deltaTotal = total - lastCpuTotal
                val deltaIdle = idleAll - lastCpuIdle
                currentCpuUsage = if (deltaTotal > 0) {
                    ((deltaTotal - deltaIdle) * 100.0 / deltaTotal)
                } else 0.0
            }
            lastCpuTotal = total
            lastCpuIdle = idleAll
        } catch (e: Exception) {
            currentCpuUsage = 0.0
        }
    }

    private fun updatePerCoreCpu() {
        try {
            val reader = BufferedReader(FileReader("/proc/stat"))
            var line = reader.readLine() // skip first "cpu" line
            var coreIdx = 0
            while (true) {
                line = reader.readLine() ?: break
                if (!line.startsWith("cpu")) break
                val parts = line.split("\\s+".toRegex())
                if (parts.size < 5) continue
                val user = parts[1].toLong()
                val nice = parts[2].toLong()
                val sys = parts[3].toLong()
                val idle = parts[4].toLong()
                val iowait = parts.getOrNull(5)?.toLong() ?: 0
                val irq = parts.getOrNull(6)?.toLong() ?: 0
                val softirq = parts.getOrNull(7)?.toLong() ?: 0

                val total = user + nice + sys + idle + iowait + irq + softirq
                val idleAll = idle + iowait

                if (coreIdx < lastCoreTotals.size && lastCoreTotals[coreIdx] > 0) {
                    val deltaTotal = total - lastCoreTotals[coreIdx]
                    val deltaIdle = idleAll - lastCoreIdles[coreIdx]
                    val usage = if (deltaTotal > 0) {
                        ((deltaTotal - deltaIdle) * 100.0 / deltaTotal)
                    } else 0.0
                    if (coreIdx < coreUsages.size) {
                        coreUsages[coreIdx] = usage
                    }
                }
                if (coreIdx < lastCoreTotals.size) {
                    lastCoreTotals[coreIdx] = total
                    lastCoreIdles[coreIdx] = idleAll
                }
                coreIdx++
            }
            reader.close()
        } catch (e: Exception) {
            // ignore
        }
    }

    private fun updateNetwork() {
        try {
            val now = System.currentTimeMillis()
            val rx = TrafficStats.getTotalRxBytes()
            val tx = TrafficStats.getTotalTxBytes()
            val delta = (now - lastNetTime) / 1000.0
            if (delta > 0) {
                downloadSpeed = ((rx - lastRxBytes) / delta) / (1024.0 * 1024.0) // MB/s
                uploadSpeed = ((tx - lastTxBytes) / delta) / (1024.0 * 1024.0)
            }
            lastRxBytes = rx
            lastTxBytes = tx
            lastNetTime = now
        } catch (e: Exception) {
            downloadSpeed = 0.0
            uploadSpeed = 0.0
        }
    }

    private fun updatePing() {
        try {
            val start = System.currentTimeMillis()
            val addr = InetAddress.getByName("8.8.8.8")
            val reachable = addr.isReachable(2000)
            if (reachable) {
                ping = (System.currentTimeMillis() - start).toDouble()
            } else {
                ping = -1.0
            }
        } catch (e: Exception) {
            ping = -1.0
        }
    }

    fun getCpuUsage(): Double = currentCpuUsage

    fun getCpuFreq(): Double {
        return try {
            var total = 0.0
            var count = 0
            for (i in 0 until Runtime.getRuntime().availableProcessors()) {
                try {
                    val f = File("/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq")
                    if (f.exists()) {
                        val freq = f.readText().trim().toLong() / 1000.0 // MHz
                        total += freq
                        count++
                    }
                } catch (_: Exception) {}
            }
            if (count > 0) total / count else 0.0
        } catch (e: Exception) { 0.0 }
    }

    fun getCpuCoreDetails(): List<Map<String, Any>> {
        val cores = mutableListOf<Map<String, Any>>()
        val numCores = Runtime.getRuntime().availableProcessors()
        for (i in 0 until numCores) {
            val freq = try {
                File("/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq")
                    .readText().trim().toLong() / 1000
            } catch (e: Exception) { 0L }
            val maxFreq = try {
                File("/sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq")
                    .readText().trim().toLong() / 1000
            } catch (e: Exception) { 0L }
            val minFreq = try {
                File("/sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_min_freq")
                    .readText().trim().toLong() / 1000
            } catch (e: Exception) { 0L }
            val gov = try {
                File("/sys/devices/system/cpu/cpu$i/cpufreq/scaling_governor")
                    .readText().trim()
            } catch (e: Exception) { "unknown" }
            val usage = if (i < coreUsages.size) coreUsages[i] else 0.0

            cores.add(mapOf(
                "core" to i,
                "frequency" to freq.toInt(),
                "maxFrequency" to maxFreq.toInt(),
                "minFrequency" to minFreq.toInt(),
                "governor" to gov,
                "usage" to usage
            ))
        }
        return cores
    }

    fun getCpuTemp(): Double {
        val paths = listOf(
            "/sys/class/thermal/thermal_zone0/temp",
            "/sys/class/thermal/thermal_zone1/temp",
            "/sys/class/thermal/thermal_zone2/temp",
            "/sys/devices/virtual/thermal/thermal_zone0/temp"
        )
        for (path in paths) {
            try {
                val f = File(path)
                if (f.exists()) {
                    val raw = f.readText().trim().toLong()
                    return if (raw > 1000) raw / 1000.0 else raw.toDouble()
                }
            } catch (_: Exception) {}
        }
        return 0.0
    }

    fun getGpuUsage(): Double {
        try {
            val paths = listOf(
                "/sys/class/kgsl/kgsl-3d0/gpu_busy_percentage",
                "/sys/class/kgsl/kgsl-3d0/gpu_load",
                "/sys/class/kgsl/kgsl-3d0/busy"
            )
            for (path in paths) {
                val f = File(path)
                if (f.exists()) {
                    val content = f.readText().trim()
                        .replace("%", "").trim()
                    val value = content.toDoubleOrNull()
                    if (value != null) {
                        return if (value > 100) value / 100.0 else value
                    }
                }
            }
        } catch (_: Exception) {}
        return 0.0
    }

    fun getGpuFreq(): Double {
        try {
            val paths = listOf(
                "/sys/class/kgsl/kgsl-3d0/devfreq/cur_freq",
                "/sys/class/kgsl/kgsl-3d0/gpuclk"
            )
            for (path in paths) {
                val f = File(path)
                if (f.exists()) {
                    val raw = f.readText().trim().toLongOrNull()
                    if (raw != null) {
                        // Typically in Hz, convert to MHz
                        return if (raw > 1000000) raw / 1000000.0 else raw / 1000.0
                    }
                }
            }
        } catch (_: Exception) {}
        return 0.0
    }

    fun getGpuTemp(): Double {
        try {
            val paths = listOf(
                "/sys/class/kgsl/kgsl-3d0/temp",
                "/sys/class/kgsl/kgsl-3d0/thermal_temp",
                "/sys/devices/platform/kgsl-3d0.0/kgsl/kgsl-3d0/temp"
            )
            for (path in paths) {
                val f = File(path)
                if (f.exists()) {
                    val raw = f.readText().trim().toLongOrNull()
                    if (raw != null) {
                        return if (raw > 100) raw / 1000.0 else raw.toDouble()
                    }
                }
            }
        } catch (_: Exception) {}
        // Fallback to CPU temp if GPU temp unavailable
        return getCpuTemp()
    }

    fun getBatteryInfo(): Map<String, Any> {
        val intentFilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val batteryStatus = context.registerReceiver(null, intentFilter)
        val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: 0
        val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: 100
        val temperature = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
        val voltage = batteryStatus?.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0) ?: 0
        val status = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: 0
        val plugged = batteryStatus?.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) ?: 0
        val health = batteryStatus?.getIntExtra(BatteryManager.EXTRA_HEALTH, 0) ?: 0

        val batteryPct = if (scale > 0) (level * 100.0 / scale) else 0.0
        val batteryTempC = temperature / 10.0

        val statusStr = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING -> "Charging"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "Discharging"
            BatteryManager.BATTERY_STATUS_FULL -> "Full"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Not Charging"
            else -> "Unknown"
        }

        val healthStr = when (health) {
            BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
            BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
            BatteryManager.BATTERY_HEALTH_UNSPECIFIED_FAILURE -> "Failure"
            else -> "Unknown"
        }

        return mapOf(
            "level" to batteryPct,
            "temperature" to batteryTempC,
            "voltage" to voltage,
            "status" to statusStr,
            "charging" to (plugged != 0),
            "health" to healthStr
        )
    }

    fun getRamInfo(): Map<String, Any> {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = ActivityManager.MemoryInfo()
        activityManager.getMemoryInfo(memoryInfo)
        val totalRam = memoryInfo.totalMem / (1024.0 * 1024 * 1024) // GB
        val usedRam = (memoryInfo.totalMem - memoryInfo.availMem) / (1024.0 * 1024 * 1024) // GB
        return mapOf("usage" to usedRam, "total" to totalRam)
    }

    fun getNetworkStats(): Map<String, Any> {
        return mapOf(
            "downloadSpeed" to downloadSpeed,
            "uploadSpeed" to uploadSpeed,
            "ping" to ping,
            "totalRx" to TrafficStats.getTotalRxBytes(),
            "totalTx" to TrafficStats.getTotalTxBytes()
        )
    }

    fun getFps(): Int = currentFps

    fun getTelemetry(): Map<String, Any> {
        updateAll()
        val cpuTemp = getCpuTemp()
        val gpuTemp = getGpuTemp()
        val ram = getRamInfo()
        val battery = getBatteryInfo()

        val throttleStatus = when {
            cpuTemp > 85 || gpuTemp > 85 -> "Critical"
            cpuTemp > 72 || gpuTemp > 72 -> "Warning"
            else -> "Normal"
        }

        return mapOf(
            "fps" to currentFps,
            "cpuUsage" to currentCpuUsage,
            "cpuFreq" to (getCpuFreq() / 1000.0), // GHz
            "cpuTemp" to cpuTemp,
            "gpuUsage" to getGpuUsage(),
            "gpuFreq" to getGpuFreq(),
            "gpuTemp" to gpuTemp,
            "ramUsage" to (ram["usage"] as? Double ?: 0.0),
            "ramTotal" to (ram["total"] as? Double ?: 0.0),
            "batteryLevel" to (battery["level"] as? Double ?: 0.0),
            "batteryTemp" to (battery["temperature"] as? Double ?: 0.0),
            "downloadSpeed" to downloadSpeed,
            "uploadSpeed" to uploadSpeed,
            "ping" to ping,
            "throttleStatus" to throttleStatus
        )
    }

    fun release() {
        frameHandler?.looper?.quit()
    }
}
