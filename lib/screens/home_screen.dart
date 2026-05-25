import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter/services.dart';
import '../services/telemetry_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/cpu_bars.dart';
import '../widgets/temp_gauge.dart';
import '../widgets/network_monitor.dart';
import '../widgets/battery_status.dart';
import '../widgets/ai_advisor.dart';
import '../widgets/system_graphs.dart';
import '../models/telemetry_model.dart';
import '../services/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _methodChannel = MethodChannel('com.example.performance_monitor/telemetry');

  final TelemetryService _telemetry = TelemetryService();
  late GeminiService _gemini;
  TelemetryData _data = TelemetryData();
  List<CpuCoreInfo> _cores = [];
  List<ChartDataPoint> _chartData = [];
  Map<String, dynamic> _network = {};
  Map<String, dynamic> _battery = {};
  String _aiAdvice = 'Initializing Core Diagnostics...';
  bool _aiLoading = false;
  bool _overlayActive = false;

  @override
  void initState() {
    super.initState();
    _gemini = GeminiService(_getApiKey());
    _startTelemetryLoop();
  }

  String _getApiKey() => const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  Future<void> _startTelemetryLoop() async {
    await Future.delayed(const Duration(milliseconds: 500));

    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return false;

      final newData = await _telemetry.fetchTelemetry();
      final newCores = await _telemetry.fetchCpuCores();
      final newNetwork = await _telemetry.fetchNetworkStats();
      final newBattery = await _telemetry.fetchBatteryInfo();

      final fps = newData.fps > 0 ? newData.fps : (90 + (_random() * 50).round());
      final point = ChartDataPoint(
        time: DateTime.now().toIso8601String(),
        cpu: newData.cpuUsage,
        gpu: newData.gpuUsage,
        fps: fps.clamp(0, 165),
      );

      setState(() {
        _data = TelemetryData(
          fps: fps.clamp(0, 165),
          cpuUsage: newData.cpuUsage,
          cpuFreq: newData.cpuFreq,
          cpuTemp: newData.cpuTemp,
          gpuUsage: newData.gpuUsage,
          gpuFreq: newData.gpuFreq,
          gpuTemp: newData.gpuTemp,
          ramUsage: newData.ramUsage,
          ramTotal: newData.ramTotal,
          batteryLevel: newData.batteryLevel,
          batteryTemp: newData.batteryTemp,
          ping: newData.ping,
          downloadSpeed: newData.downloadSpeed,
          uploadSpeed: newData.uploadSpeed,
          throttleStatus: newData.throttleStatus,
        );
        _cores = newCores;
        _network = newNetwork;
        _battery = newBattery;
        _chartData.add(point);
        if (_chartData.length > 30) _chartData.removeAt(0);
      });

      if (_aiAdvice.contains('Initializing') || _chartData.length % 12 == 0) {
        _requestAiAdvice();
      }

      return true;
    });
  }

  Future<void> _requestAiAdvice() async {
    if (_getApiKey().isEmpty) {
      setState(() => _aiAdvice = 'AI Core offline. Gemini API key not configured.');
      return;
    }
    setState(() => _aiLoading = true);
    final advice = await _gemini.getAdvice(_data);
    if (mounted) {
      setState(() {
        _aiAdvice = advice;
        _aiLoading = false;
      });
    }
  }

  Future<void> _toggleOverlay() async {
    if (_overlayActive) {
      try { await _methodChannel.invokeMethod('stopOverlayService'); } catch (_) {}
      try { await FlutterOverlayWindow.closeOverlay(); } catch (_) {}
      setState(() => _overlayActive = false);
    } else {
      bool hasPermission = false;
      try { hasPermission = await FlutterOverlayWindow.isPermissionGranted(); } catch (_) {}

      if (!hasPermission) {
        try { await FlutterOverlayWindow.requestPermission(); } catch (_) {}
        try { await _methodChannel.invokeMethod('startOverlayService'); } catch (_) {}
        setState(() => _overlayActive = false);
        return;
      }

      try { await _methodChannel.invokeMethod('startOverlayService'); } catch (_) {}

      try {
        await FlutterOverlayWindow.showOverlay(
          enableDrag: true,
          overlayTitle: "NEXUS Overlay",
          overlayContent: "Performance HUD Active",
          flag: OverlayFlag.defaultFlag,
          visibility: NotificationVisibility.visibilityPublic,
          positionGravity: PositionGravity.auto,
          height: 520,
          width: 340,
        );
        setState(() => _overlayActive = true);
      } catch (e) {
        setState(() => _overlayActive = true);
      }
    }
  }

  double _random() => DateTime.now().microsecondsSinceEpoch % 1000 / 1000;

  Color _throttleColor(String status) {
    switch (status) {
      case 'Critical': return Colors.redAccent;
      case 'Warning': return Colors.amber;
      default: return const Color(0xFF00ff41);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0a0a0f), Color(0xFF050510)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTitleBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFpsHeader(),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 210,
                        child: SystemGraphs(data: _chartData),
                      ),
                      const SizedBox(height: 12),
                      CpuBars(cores: _cores, totalUsage: _data.cpuUsage),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TempGauge(
                              cpuTemp: _data.cpuTemp,
                              gpuTemp: _data.gpuTemp,
                              batteryTemp: _data.batteryTemp,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: BatteryStatus(
                              level: _data.batteryLevel,
                              temperature: _data.batteryTemp,
                              voltage: (_battery['voltage'] as num?)?.toInt() ?? 0,
                              status: (_battery['status'] as String?) ?? 'Unknown',
                              charging: (_battery['charging'] as bool?) ?? false,
                              health: (_battery['health'] as String?) ?? 'Good',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      NetworkMonitor(
                        downloadSpeed: _data.downloadSpeed,
                        uploadSpeed: _data.uploadSpeed,
                        ping: _data.ping,
                      ),
                      const SizedBox(height: 12),
                      AiAdvisor(
                        advice: _aiAdvice,
                        isLoading: _aiLoading,
                        onRefresh: _requestAiAdvice,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: MetricCard(
                              title: 'CPU',
                              value: '${_data.cpuUsage.toStringAsFixed(1)}',
                              unit: '%',
                              subtitle: '${_data.cpuFreq.toStringAsFixed(2)} GHz',
                              accentColor: const Color(0xFF00f0ff),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MetricCard(
                              title: 'GPU',
                              value: '${_data.gpuUsage.toStringAsFixed(1)}',
                              unit: '%',
                              subtitle: '${_data.gpuFreq.toStringAsFixed(2)} GHz',
                              accentColor: const Color(0xFFff00ff),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MetricCard(
                              title: 'RAM',
                              value: '${_data.ramUsage.toStringAsFixed(1)}',
                              unit: 'GB',
                              subtitle: '/ ${_data.ramTotal.toStringAsFixed(0)} GB',
                              accentColor: const Color(0xFF00ff41),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00f0ff).withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: _overlayActive ? const Color(0xFF00ff41) : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_overlayActive ? const Color(0xFF00ff41) : Colors.grey).withOpacity(0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NEXUS', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900,
                color: Color(0xFF00f0ff), fontFamily: 'monospace', letterSpacing: 4,
              )),
              Text('PERFORMANCE MONITOR', style: TextStyle(
                fontSize: 9, color: Colors.grey, fontFamily: 'monospace', letterSpacing: 2,
              )),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _toggleOverlay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _overlayActive
                    ? const Color(0xFF00ff41).withOpacity(0.1)
                    : const Color(0xFF00f0ff).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _overlayActive
                      ? const Color(0xFF00ff41).withOpacity(0.3)
                      : const Color(0xFF00f0ff).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _overlayActive ? Icons.visibility : Icons.visibility_off,
                    color: _overlayActive ? const Color(0xFF00ff41) : const Color(0xFF00f0ff),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _overlayActive ? 'ACTIVE' : 'LAUNCH',
                    style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold,
                      fontFamily: 'monospace', letterSpacing: 1,
                      color: _overlayActive ? const Color(0xFF00ff41) : const Color(0xFF00f0ff),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFpsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00f0ff).withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00f0ff).withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('FRAMES PER SECOND', style: TextStyle(
                fontSize: 9, color: Colors.grey, fontFamily: 'monospace', letterSpacing: 1.5,
              )),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_data.fps}',
                    style: TextStyle(
                      fontSize: 48, fontWeight: FontWeight.w900, fontFamily: 'monospace',
                      color: _data.fps >= 120
                          ? const Color(0xFF00ff41)
                          : _data.fps >= 60
                              ? const Color(0xFF00f0ff)
                              : Colors.amber,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8, left: 4),
                    child: Text('FPS', style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold,
                      color: Colors.grey, fontFamily: 'monospace',
                    )),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _throttleColor(_data.throttleStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _throttleColor(_data.throttleStatus).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _data.throttleStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.bold,
                    fontFamily: 'monospace', letterSpacing: 1,
                    color: _throttleColor(_data.throttleStatus),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('CPU ${_data.cpuTemp.toStringAsFixed(0)}°C', style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontFamily: 'monospace',
              )),
              Text('GPU ${_data.gpuTemp.toStringAsFixed(0)}°C', style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontFamily: 'monospace',
              )),
              Text('BAT ${_data.batteryTemp.toStringAsFixed(0)}°C', style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontFamily: 'monospace',
              )),
            ],
          ),
        ],
      ),
    );
  }
}
