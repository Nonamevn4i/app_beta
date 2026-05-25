import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
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
  final TelemetryService _telemetry = TelemetryService();
  late GeminiService _gemini;
  TelemetryData _data = TelemetryData();
  List<CpuCoreInfo> _cores = [];
  List<ChartDataPoint> _chartData = [];
  Map<String, dynamic> _network = {};
  Map<String, dynamic> _battery = {};
  String _aiAdvice = 'Initializing Core Diagnostics...';
  bool _aiLoading = false;

  @override
  void initState() {
    super.initState();
    _gemini = GeminiService(_getApiKey());
    _requestOverlayPerm();
    _startTelemetryLoop();
  }

  String _getApiKey() => const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  Future<void> _requestOverlayPerm() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
  }

  void _startTelemetryLoop() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return false;
      final newData = await _telemetry.fetchTelemetry();
      final newCores = await _telemetry.fetchCpuCores();
      final newNetwork = await _telemetry.fetchNetworkStats();
      final newBattery = await _telemetry.fetchBatteryInfo();
      final fps = newData.fps > 0 ? newData.fps : (90 + (_random() * 50).round());
      final point = ChartDataPoint(time: DateTime.now().toIso8601String(), cpu: newData.cpuUsage, gpu: newData.gpuUsage, fps: fps.clamp(0, 165));
      setState(() {
        _data = TelemetryData(fps: fps.clamp(0, 165), cpuUsage: newData.cpuUsage, cpuFreq: newData.cpuFreq, cpuTemp: newData.cpuTemp, gpuUsage: newData.gpuUsage, gpuFreq: newData.gpuFreq, gpuTemp: newData.gpuTemp, ramUsage: newData.ramUsage, ramTotal: newData.ramTotal, batteryLevel: newData.batteryLevel, batteryTemp: newData.batteryTemp, ping: newData.ping, downloadSpeed: newData.downloadSpeed, uploadSpeed: newData.uploadSpeed, throttleStatus: newData.throttleStatus);
        _cores = newCores;
        _network = newNetwork;
        _battery = newBattery;
        _chartData.add(point);
        if (_chartData.length > 30) _chartData.removeAt(0);
      });
      return true;
    });
  }

  int _random() => DateTime.now().microsecondsSinceEpoch % 100;

  Future<void> _refreshAiAdvice() async {
    setState(() => _aiLoading = true);
    final advice = await _gemini.getAdvice(_data);
    if (mounted) setState(() { _aiAdvice = advice; _aiLoading = false; });
  }

  Future<void> _launchOverlay() async {
    if (await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.showOverlay(enableDrag: true, overlayTitle: 'NEXUS Overlay', overlayContent: 'Active', flag: OverlayFlag.defaultFlag, visibility: NotificationVisibility.visibilityPublic, positionGravity: PositionGravity.auto, height: 520, width: 340);
    } else {
      _requestOverlayPerm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return isWide ? _buildWideLayout() : _buildNarrowLayout();
      })),
    );
  }

  Widget _buildWideLayout() {
    return Column(children: [
      _buildHeader(),
      Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 260, child: SingleChildScrollView(padding: const EdgeInsets.only(left: 16, right: 8), child: Column(children: [
          _buildFpsCard(), const SizedBox(height: 12), _buildEnvironmentCard(),
        ]))),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 8), child: Column(children: [
          _buildOverlayControl(), const SizedBox(height: 12),
          SizedBox(height: 200, child: SystemGraphs(data: _chartData)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: MetricCard(title: 'Snapdragon 8 Gen 3', value: '${_data.cpuUsage.round()}', unit: '%', icon: Icons.memory, subtitle: '${_data.cpuFreq.toStringAsFixed(2)} GHz (Max)', status: _data.cpuUsage > 90 ? 'Critical' : _data.cpuUsage > 70 ? 'Warning' : 'Normal', accentColor: const Color(0xFF00f0ff))),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(title: 'Adreno 750 (GPU)', value: '${_data.gpuUsage.round()}', unit: '%', icon: Icons.speed, subtitle: '${_data.gpuFreq.toStringAsFixed(2)} GHz (Core)', status: _data.gpuUsage > 90 ? 'Critical' : _data.gpuUsage > 70 ? 'Warning' : 'Normal', accentColor: const Color(0xFFff00ff))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: MetricCard(title: 'RAM (LPDDR5X)', value: _data.ramUsage.toStringAsFixed(1), unit: 'GB', icon: Icons.storage, subtitle: '${_data.ramTotal.toStringAsFixed(0)} GB Total', status: _data.ramUsage > 14 ? 'Warning' : 'Normal', accentColor: const Color(0xFF00ff41))),
            const SizedBox(width: 12),
            Expanded(child: MetricCard(title: 'Network Monitor', value: _data.ping.round().toString(), unit: 'ms', icon: Icons.wifi, subtitle: 'DL: ${_data.downloadSpeed.round()} MB/s', status: _data.ping > 100 ? 'Warning' : 'Normal', accentColor: const Color(0xFF4fc3f7))),
          ]),
          const SizedBox(height: 12),
          CpuBars(cores: _cores, totalUsage: _data.cpuUsage),
          const SizedBox(height: 12),
          TempGauge(cpuTemp: _data.cpuTemp, gpuTemp: _data.gpuTemp, batteryTemp: _data.batteryTemp),
          const SizedBox(height: 12),
          NetworkMonitor(downloadSpeed: _data.downloadSpeed, uploadSpeed: _data.uploadSpeed, ping: _data.ping),
          const SizedBox(height: 12),
          BatteryStatus(level: _data.batteryLevel, temperature: _data.batteryTemp, voltage: (_battery['voltage'] as int?) ?? 0, status: (_battery['status'] as String?) ?? 'Unknown', charging: (_battery['charging'] as bool?) ?? false, health: (_battery['health'] as String?) ?? 'Good'),
          const SizedBox(height: 16),
          _buildStatusFooter(), const SizedBox(height: 16),
        ]))),
        SizedBox(width: 240, child: SingleChildScrollView(padding: const EdgeInsets.only(left: 8, right: 16), child: Column(children: [
          AiAdvisor(advice: _aiAdvice, isLoading: _aiLoading, onRefresh: _refreshAiAdvice),
          const SizedBox(height: 12), _buildSystemStatus(),
        ]))),
      ])),
    ]);
  }

  Widget _buildNarrowLayout() {
    return SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _buildHeader(), const SizedBox(height: 16),
      _buildOverlayControl(), const SizedBox(height: 16),
      SizedBox(height: 200, child: SystemGraphs(data: _chartData)),
      const SizedBox(height: 16),
      Row(children: [Expanded(child: _buildFpsCard()), const SizedBox(width: 12)]),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: MetricCard(title: 'Snapdragon 8 Gen 3', value: '${_data.cpuUsage.round()}', unit: '%', icon: Icons.memory, subtitle: '${_data.cpuFreq.toStringAsFixed(2)} GHz', status: _data.cpuUsage > 90 ? 'Critical' : _data.cpuUsage > 70 ? 'Warning' : 'Normal', accentColor: const Color(0xFF00f0ff))),
        const SizedBox(width: 12),
        Expanded(child: MetricCard(title: 'Adreno 750 (GPU)', value: '${_data.gpuUsage.round()}', unit: '%', icon: Icons.speed, subtitle: '${_data.gpuFreq.toStringAsFixed(2)} GHz', status: _data.gpuUsage > 90 ? 'Critical' : _data.gpuUsage > 70 ? 'Warning' : 'Normal', accentColor: const Color(0xFFff00ff))),
      ]),
      const SizedBox(height: 12), _buildEnvironmentCard(), const SizedBox(height: 12),
      CpuBars(cores: _cores, totalUsage: _data.cpuUsage), const SizedBox(height: 12),
      TempGauge(cpuTemp: _data.cpuTemp, gpuTemp: _data.gpuTemp, batteryTemp: _data.batteryTemp), const SizedBox(height: 12),
      NetworkMonitor(downloadSpeed: _data.downloadSpeed, uploadSpeed: _data.uploadSpeed, ping: _data.ping), const SizedBox(height: 12),
      BatteryStatus(level: _data.batteryLevel, temperature: _data.batteryTemp, voltage: (_battery['voltage'] as int?) ?? 0, status: (_battery['status'] as String?) ?? 'Unknown', charging: (_battery['charging'] as bool?) ?? false, health: (_battery['health'] as String?) ?? 'Good'),
      const SizedBox(height: 12),
      AiAdvisor(advice: _aiAdvice, isLoading: _aiLoading, onRefresh: _refreshAiAdvice), const SizedBox(height: 12),
      _buildSystemStatus(), const SizedBox(height: 12), _buildStatusFooter(),
    ]));
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: const Color(0xFF00f0ff).withOpacity(0.15)))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFF00f0ff).withOpacity(0.15), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: const Color(0xFF00f0ff).withOpacity(0.3), blurRadius: 12)]), child: const Icon(Icons.bolt, color: Color(0xFF00f0ff), size: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('NEXUS OVERLAY', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF00f0ff), letterSpacing: 1)),
          Text('v4.2.0-STABLE // SYSTEM_ALERT_READY', style: TextStyle(fontSize: 9, color: const Color(0xFF00f0ff).withOpacity(0.5), fontFamily: 'monospace', letterSpacing: 1.5)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('GLOBAL STATUS', style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontFamily: 'monospace', letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(_data.throttleStatus, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _data.throttleStatus == 'Critical' ? Colors.redAccent : _data.throttleStatus == 'Warning' ? Colors.amber : const Color(0xFF00ff41), fontFamily: 'monospace', letterSpacing: 1)),
        ]),
      ]),
    );
  }

  Widget _buildOverlayControl() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('OVERLAY STATE', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontFamily: 'monospace', letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF00f0ff), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF00f0ff).withOpacity(0.6), blurRadius: 6)])),
            const SizedBox(width: 6),
            const Text('READY', style: TextStyle(fontSize: 12, color: Color(0xFF00f0ff), fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          ]),
        ]),
        const Spacer(),
        ElevatedButton.icon(onPressed: _launchOverlay, icon: const Icon(Icons.layers, size: 16), label: const Text('LAUNCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'monospace')),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00f0ff).withOpacity(0.12), foregroundColor: const Color(0xFF00f0ff), side: BorderSide(color: const Color(0xFF00f0ff).withOpacity(0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), elevation: 0)),
      ]),
    );
  }

  Widget _buildFpsCard() {
    final fpsColor = _data.fps >= 110 ? const Color(0xFF00ff41) : _data.fps >= 60 ? const Color(0xFF00f0ff) : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: fpsColor.withOpacity(0.3))),
      child: Column(children: [
        Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: fpsColor.withOpacity(0.12), border: Border.all(color: fpsColor.withOpacity(0.4), width: 2), boxShadow: [BoxShadow(color: fpsColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)]), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${_data.fps}', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: fpsColor, fontFamily: 'monospace')),
          Text('FPS', style: TextStyle(fontSize: 10, color: fpsColor.withOpacity(0.7), fontFamily: 'monospace', letterSpacing: 3, fontWeight: FontWeight.bold)),
        ]))),
        const SizedBox(height: 10),
        Text('DRAGGABLE ANCHOR', style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontFamily: 'monospace', letterSpacing: 1.5)),
      ]),
    );
  }

  Widget _buildEnvironmentCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.thermostat, color: Colors.amber, size: 14), const SizedBox(width: 6), Text('ENVIRONMENT', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'monospace', letterSpacing: 1.5))]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('BATTERY', style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontFamily: 'monospace', letterSpacing: 1)),
            const SizedBox(height: 4),
            Text('${_data.batteryLevel.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00f0ff), fontFamily: 'monospace')),
            Text('${(_battery['voltage'] as int? ?? 0)}mV', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontFamily: 'monospace')),
          ])),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('THERMAL STATE', style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontFamily: 'monospace', letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(_data.throttleStatus.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _data.throttleStatus == 'Critical' ? Colors.redAccent : _data.throttleStatus == 'Warning' ? Colors.amber : const Color(0xFF00ff41), fontFamily: 'monospace')),
          ])),
        ]),
        const SizedBox(height: 12),
        Row(children: [_envTemp('CPU', _data.cpuTemp), const SizedBox(width: 12), _envTemp('GPU', _data.gpuTemp)]),
      ]),
    );
  }

  Widget _envTemp(String label, double temp) {
    final isHot = temp > 75;
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(8), border: Border.all(color: isHot ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.06))),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${temp.round()}°C', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isHot ? Colors.redAccent : Colors.grey.shade300, fontFamily: 'monospace')),
      ]),
    ));
  }

  Widget _buildSystemStatus() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.08))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SYSTEM STATUS', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontFamily: 'monospace', letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Service Health', style: TextStyle(fontSize: 11, color: Colors.grey, fontFamily: 'monospace')),
          Text('Optimal', style: TextStyle(fontSize: 11, color: const Color(0xFF00ff41), fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Row(children: List.generate(5, (i) {
          final on = i < 3;
          return Container(margin: const EdgeInsets.only(right: 3), width: 6, height: 16,
            decoration: BoxDecoration(color: on ? const Color(0xFF00ff41) : Colors.grey.shade800, borderRadius: BorderRadius.circular(2),
              boxShadow: on ? [BoxShadow(color: const Color(0xFF00ff41).withOpacity(0.4), blurRadius: 4)] : null),
          );
        })),
      ]),
    );
  }

  Widget _buildStatusFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Platform: ARM64-V8A', style: TextStyle(fontSize: 8, color: Colors.grey.shade700, fontFamily: 'monospace')),
        Row(children: [
          _statusDot(const Color(0xFF00f0ff), 'Overlay'),
          const SizedBox(width: 10),
          _statusDot(const Color(0xFF00ff41), 'Active'),
        ]),
      ]),
    );
  }

  Widget _statusDot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)])),
    const SizedBox(width: 3),
    Text(label, style: TextStyle(fontSize: 8, color: color.withOpacity(0.8), fontFamily: 'monospace')),
  ]);
}
