import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../services/telemetry_service.dart';
import '../models/telemetry_model.dart';
import '../widgets/fps_display.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  final TelemetryService _telemetry = TelemetryService();
  TelemetryData _data = TelemetryData();
  List<CpuCoreInfo> _cores = [];
  int _fps = 120;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _startTelemetry();
    _startFpsTracker();
  }

  void _startTelemetry() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      final d = await _telemetry.fetchTelemetry();
      final c = await _telemetry.fetchCpuCores();
      setState(() { _data = d; _cores = c; });
      return true;
    });
  }

  void _startFpsTracker() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return false;
      final variation = (DateTime.now().microsecondsSinceEpoch % 20) - 10;
      setState(() { _fps = (_fps + variation).clamp(30, 165); });
      return true;
    });
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    FlutterOverlayWindow.resizeOverlay(_isExpanded ? 340 : 80, _isExpanded ? 520 : 80, true);
  }

  Color get _throttleColor {
    switch (_data.throttleStatus) {
      case 'Critical': return Colors.redAccent;
      case 'Warning': return Colors.amber;
      default: return const Color(0xFF00ff41);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return GestureDetector(onTap: _toggleExpand, child: FpsDisplay(fps: _fps, size: 76, onToggleMinimize: _toggleExpand));
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0a0a0f).withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00f0ff).withOpacity(0.15)),
          boxShadow: [BoxShadow(color: const Color(0xFF00f0ff).withOpacity(0.08), blurRadius: 20, spreadRadius: 2)],
        ),
        child: Column(children: [
          _buildTitleBar(),
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(10), child: Column(children: [
            _buildFpsRow(), const SizedBox(height: 10),
            _buildMetricBar('CPU', '${_data.cpuUsage.toStringAsFixed(1)}%', '${_data.cpuFreq.toStringAsFixed(2)} GHz', Colors.cyanAccent, _data.cpuUsage / 100, _data.cpuUsage > 90),
            const SizedBox(height: 8),
            _buildMetricBar('GPU', '${_data.gpuUsage.toStringAsFixed(1)}%', '${_data.gpuFreq.toStringAsFixed(2)} GHz', const Color(0xFFff00ff), _data.gpuUsage / 100, _data.gpuUsage > 90),
            const SizedBox(height: 12),
            _buildTempRow(), const SizedBox(height: 10),
            _buildCompactStats(), const SizedBox(height: 8),
            _buildMiniCores(), const SizedBox(height: 8),
            _buildRamBar(),
          ]))),
        ]),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(color: Color(0xFF1a1a20), borderRadius: BorderRadius.vertical(top: Radius.circular(15))),
      child: Row(children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: _throttleColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _throttleColor.withOpacity(0.6), blurRadius: 4)])),
        const SizedBox(width: 6),
        const Expanded(child: Text('NEXUS', style: TextStyle(color: Color(0xFF00f0ff), fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace', letterSpacing: 1))),
        GestureDetector(child: Icon(Icons.horizontal_rule, color: Colors.grey.shade500, size: 16), onTap: _toggleExpand),
        const SizedBox(width: 10),
        GestureDetector(child: const Icon(Icons.close, color: Colors.redAccent, size: 16), onTap: () => FlutterOverlayWindow.closeOverlay()),
      ]),
    );
  }

  Widget _buildFpsRow() {
    final fpsColor = _fps >= 110 ? const Color(0xFF00ff41) : _fps >= 60 ? const Color(0xFF00f0ff) : Colors.redAccent;
    return Row(children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: fpsColor.withOpacity(0.1), border: Border.all(color: fpsColor.withOpacity(0.4), width: 1.5), boxShadow: [BoxShadow(color: fpsColor.withOpacity(0.2), blurRadius: 8)]),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$_fps', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: fpsColor, fontFamily: 'monospace')),
          Text('FPS', style: TextStyle(fontSize: 7, color: fpsColor.withOpacity(0.7), fontFamily: 'monospace', letterSpacing: 1)),
        ]))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [_miniDot(const Color(0xFF00f0ff)), const SizedBox(width: 4), Text('CPU ${_data.cpuUsage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 8, color: Colors.grey.shade400, fontFamily: 'monospace')), const Spacer(), Text('${_data.cpuTemp.toStringAsFixed(0)}°C', style: TextStyle(fontSize: 8, color: _data.cpuTemp > 75 ? Colors.redAccent : Colors.grey.shade500, fontFamily: 'monospace'))]),
        const SizedBox(height: 4),
        Row(children: [_miniDot(const Color(0xFFff00ff)), const SizedBox(width: 4), Text('GPU ${_data.gpuUsage.toStringAsFixed(1)}%', style: TextStyle(fontSize: 8, color: Colors.grey.shade400, fontFamily: 'monospace')), const Spacer(), Text('${_data.gpuTemp.toStringAsFixed(0)}°C', style: TextStyle(fontSize: 8, color: _data.gpuTemp > 75 ? Colors.redAccent : Colors.grey.shade500, fontFamily: 'monospace'))]),
        const SizedBox(height: 6),
        Row(children: [const Icon(Icons.wifi, size: 8, color: Color(0xFF4fc3f7)), const SizedBox(width: 4), Text('${_data.ping.toStringAsFixed(0)}ms', style: TextStyle(fontSize: 8, color: Colors.grey.shade500, fontFamily: 'monospace')), const Spacer(), Text(_data.throttleStatus.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: _throttleColor, fontFamily: 'monospace'))]),
      ])),
    ]);
  }

  Widget _miniDot(Color color) => Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _buildMetricBar(String label, String value, String freq, Color color, double progress, bool isCritical) {
    return Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8), border: Border.all(color: isCritical ? Colors.redAccent.withOpacity(0.3) : color.withOpacity(0.1))),
      child: Row(children: [
        SizedBox(width: 28, child: Text(label, style: TextStyle(fontSize: 9, color: color, fontFamily: 'monospace', fontWeight: FontWeight.bold))),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(value: progress.clamp(0, 1), backgroundColor: Colors.white.withOpacity(0.04), valueColor: AlwaysStoppedAnimation<Color>(isCritical ? Colors.redAccent : color), minHeight: 4))),
        const SizedBox(width: 8), Text(value, style: TextStyle(fontSize: 9, color: color, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        const SizedBox(width: 6), Text(freq, style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontFamily: 'monospace')),
      ]),
    );
  }

  Widget _buildTempRow() => Row(children: [
    _compactBlock(Icons.thermostat, '${_data.cpuTemp.toStringAsFixed(0)}°', 'CPU', _data.cpuTemp > 75 ? Colors.redAccent : const Color(0xFF00f0ff)),
    const SizedBox(width: 6),
    _compactBlock(Icons.thermostat, '${_data.gpuTemp.toStringAsFixed(0)}°', 'GPU', _data.gpuTemp > 75 ? Colors.redAccent : const Color(0xFFff00ff)),
    const SizedBox(width: 6),
    _compactBlock(Icons.battery_std, '${_data.batteryLevel.toStringAsFixed(0)}%', 'BAT', Colors.amber),
  ]);

  Widget _compactBlock(IconData icon, String value, String label, Color color) => Expanded(child: Container(
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
    child: Column(children: [
      Icon(icon, color: color, size: 14), const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color, fontFamily: 'monospace')),
      Text(label, style: TextStyle(fontSize: 7, color: Colors.grey.shade600, fontFamily: 'monospace')),
    ]),
  ));

  Widget _buildCompactStats() => Row(children: [
    _compactBlock(Icons.wifi, '${_data.ping.toStringAsFixed(0)}ms', 'PING', const Color(0xFF00ff41)),
    const SizedBox(width: 6),
    _compactBlock(Icons.arrow_downward, '${_data.downloadSpeed.toStringAsFixed(1)}', 'DL MB/s', const Color(0xFF00f0ff)),
    const SizedBox(width: 6),
    _compactBlock(Icons.arrow_upward, '${_data.uploadSpeed.toStringAsFixed(1)}', 'UL MB/s', const Color(0xFFff00ff)),
  ]);

  Widget _buildMiniCores() {
    final displayCores = _cores.length >= 4 ? _cores.sublist(0, 4) : _cores;
    if (displayCores.isEmpty) return const SizedBox.shrink();
    return Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CORES', style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontFamily: 'monospace', letterSpacing: 1)),
        const SizedBox(height: 6),
        ...List.generate(displayCores.length, (i) {
          final core = displayCores[i];
          final pct = (core.maxFrequency > 0 ? core.maxFrequency : 3200) > 0 ? (core.frequency / (core.maxFrequency > 0 ? core.maxFrequency : 3200)) : 0.0;
          return Padding(padding: const EdgeInsets.only(bottom: 3), child: Row(children: [
            SizedBox(width: 22, child: Text('C${core.core}', style: TextStyle(fontSize: 7, color: Colors.grey.shade600, fontFamily: 'monospace'))),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: pct.clamp(0, 1), backgroundColor: Colors.white.withOpacity(0.04),
                valueColor: AlwaysStoppedAnimation<Color>(pct > 0.8 ? Colors.redAccent : pct > 0.5 ? Colors.amber : const Color(0xFF00f0ff)), minHeight: 3))),
            SizedBox(width: 36, child: Text('${core.frequency}MHz', style: TextStyle(fontSize: 7, color: Colors.grey.shade600, fontFamily: 'monospace'), textAlign: TextAlign.right)),
          ]));
        }),
      ]),
    );
  }

  Widget _buildRamBar() {
    final used = _data.ramUsage;
    final total = _data.ramTotal > 0 ? _data.ramTotal : 12;
    return Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        const Icon(Icons.storage, color: Color(0xFF00ff41), size: 12), const SizedBox(width: 6),
        Text('RAM', style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(value: (total > 0 ? (used / total) : 0.0).clamp(0, 1), backgroundColor: Colors.white.withOpacity(0.04),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00ff41)), minHeight: 4))),
        const SizedBox(width: 8),
        Text('${used.toStringAsFixed(1)}/${total.toStringAsFixed(0)}GB', style: TextStyle(fontSize: 8, color: Colors.grey.shade500, fontFamily: 'monospace')),
      ]),
    );
  }
}
