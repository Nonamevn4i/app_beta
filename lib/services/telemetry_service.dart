import 'package:flutter/services.dart';
import '../models/telemetry_model.dart';

class TelemetryService {
  static const _channel = MethodChannel('com.example.performance_monitor/telemetry');

  TelemetryData _lastKnown = TelemetryData();
  List<CpuCoreInfo> _lastCores = [];
  int _nativeFps = 0;

  TelemetryData get lastKnown => _lastKnown;
  List<CpuCoreInfo> get lastCores => _lastCores;

  // Try to get real data, fall back to simulated on error
  Future<TelemetryData> fetchTelemetry() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getTelemetry');
      if (result != null) {
        final map = Map<String, dynamic>.from(result);
        _lastKnown = TelemetryData.fromMap(map);
        _nativeFps = _lastKnown.fps;
        return _lastKnown;
      }
    } catch (e) {
      // Native channel failed, fall back to simulated
    }
    return _simulatedTelemetry();
  }

  Future<List<CpuCoreInfo>> fetchCpuCores() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getCpuCores');
      if (result != null) {
        _lastCores = result.map((e) {
          return CpuCoreInfo.fromMap(Map<String, dynamic>.from(e as Map));
        }).toList();
        return _lastCores;
      }
    } catch (e) {
      // Fall back to simulated
    }
    return _simulatedCores();
  }

  Future<Map<String, dynamic>> fetchNetworkStats() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getNetworkStats');
      if (result != null) return Map<String, dynamic>.from(result);
    } catch (e) {}
    return _simulatedNetwork();
  }

  Future<Map<String, dynamic>> fetchBatteryInfo() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getBatteryInfo');
      if (result != null) return Map<String, dynamic>.from(result);
    } catch (e) {}
    return _simulatedBattery();
  }

  // --- Simulated fallbacks ---

  TelemetryData _simulatedTelemetry() {
    final cpu = 15.0 + (_random() * 70);
    final gpu = 20.0 + (_random() * 60);
    final cpuT = 40.0 + (cpu * 0.4);
    final gpuT = 45.0 + (gpu * 0.4);
    String throttle = 'Normal';
    if (cpuT > 80 || gpuT > 80) throttle = 'Critical';
    else if (cpuT > 68 || gpuT > 68) throttle = 'Warning';
    return TelemetryData(
      fps: _nativeFps > 0 ? _nativeFps : 120,
      cpuUsage: cpu, cpuFreq: 1.2 + (cpu / 100) * 2.8,
      cpuTemp: cpuT, gpuUsage: gpu, gpuFreq: 0.5 + (gpu / 100) * 1.5,
      gpuTemp: gpuT, ramUsage: 3.2 + _random() * 4, ramTotal: 12,
      batteryLevel: _lastKnown.batteryLevel > 0
          ? (_lastKnown.batteryLevel - 0.01 * (cpu + gpu) / 100).clamp(0, 100) : 85,
      batteryTemp: 28 + _random() * 10, ping: 15 + _random() * 40,
      downloadSpeed: _random() * 200, uploadSpeed: _random() * 50,
      throttleStatus: throttle,
    );
  }

  List<CpuCoreInfo> _simulatedCores() {
    return List.generate(8, (i) {
      final freq = 800 + (_random() * 2400).round();
      return CpuCoreInfo(
        core: i, frequency: freq, maxFrequency: 3200,
        minFrequency: 300, governor: i < 4 ? 'performance' : 'schedutil',
      );
    });
  }

  Map<String, dynamic> _simulatedNetwork() => {
    'downloadSpeed': _random() * 150, 'uploadSpeed': _random() * 30,
    'ping': 15 + _random() * 40, 'totalRx': 1024 * 1024 * 1024, 'totalTx': 512 * 1024 * 1024,
  };

  Map<String, dynamic> _simulatedBattery() => {
    'level': _lastKnown.batteryLevel > 0 ? _lastKnown.batteryLevel : 85,
    'temperature': 28 + _random() * 10, 'voltage': 3800 + (_random() * 400).round(),
    'status': 'Discharging', 'charging': false, 'health': 'Good',
  };

  double _random() => DateTime.now().microsecondsSinceEpoch % 1000 / 1000;
}
