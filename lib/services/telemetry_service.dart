import 'package:flutter/services.dart';
import '../models/telemetry_model.dart';

class TelemetryService {
  static const _channel = MethodChannel('com.example.performance_monitor/telemetry');

  TelemetryData _lastKnown = TelemetryData();
  List<CpuCoreInfo> _lastCores = [];

  TelemetryData get lastKnown => _lastKnown;
  List<CpuCoreInfo> get lastCores => _lastCores;

  Future<TelemetryData> fetchTelemetry() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getTelemetry');
      if (result != null) {
        _lastKnown = TelemetryData.fromMap(Map<String, dynamic>.from(result));
      }
    } catch (e) {
      _lastKnown = _simulatedTelemetry();
    }
    return _lastKnown;
  }

  Future<List<CpuCoreInfo>> fetchCpuCores() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getCpuCores');
      if (result != null) {
        _lastCores = result.map((e) => CpuCoreInfo.fromMap(Map<String, dynamic>.from(e))).toList();
      }
    } catch (e) {
      _lastCores = _simulatedCores();
    }
    return _lastCores;
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

  TelemetryData _simulatedTelemetry() {
    final cpu = 15.0 + (_random() * 70);
    final gpu = 20.0 + (_random() * 60);
    final cpuT = 40.0 + (cpu * 0.4);
    final gpuT = 45.0 + (gpu * 0.4);
    String throttle = 'Normal';
    if (cpuT > 80 || gpuT > 80) throttle = 'Critical';
    else if (cpuT > 68 || gpuT > 68) throttle = 'Warning';
    return TelemetryData(
      fps: _lastKnown.fps > 0 ? _lastKnown.fps : 120,
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
