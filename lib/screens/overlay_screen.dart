import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter/services.dart';
import '../services/telemetry_service.dart';
import '../models/telemetry_model.dart';
import '../widgets/fps_display.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({super.key});

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  static const _methodChannel = MethodChannel('com.example.performance_monitor/telemetry');

  final TelemetryService _telemetry = TelemetryService();
  TelemetryData _data = TelemetryData();
  List<CpuCoreInfo> _cores = [];
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _startTelemetry();
  }

  void _startTelemetry() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return false;

      try {
        final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>('getTelemetry');
        if (result != null) {
          final map = Map<String, dynamic>.from(result);
          _data = TelemetryData.fromMap(map);
        }
      } catch (_) {
        // Fall back to simulated
        final d = await _telemetry.fetchTelemetry();
        _data = d;
      }

      try {
        final result = await _methodChannel.invokeMethod<List<dynamic>>('getCpuCores');
        if (result != null) {
          _cores = result.map((e) =>
              CpuCoreInfo.fromMap(Map<String, dynamic>.from(e as Map))).toList();
        }
      } catch (_) {
        final c = await _telemetry.fetchCpuCores();
        _cores = c;
      }

      if (mounted) setState(() {});
      return true;
    });
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    FlutterOverlayWindow.resizeOverlay(
      _isExpanded ? 340 : 80,
      _isExpanded ? 520 : 80,
      true,
    );
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
      return GestureDetector(
        onTap: _toggleExpand,
        child: FpsDisplay(
          fps: _data.fps,
          size: 76,
          onToggleMinimize: _toggleExpand,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0a0a0f).withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00f0ff).withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00f0ff).withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTitleBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    _buildFpsRow(),
                    const SizedBox(height: 10),
                    _buildInfoRow('CPU', '${_data.cpuUsage.toStringAsFixed(1)}%',
                        '${_data.cpuFreq.toStringAsFixed(2)} GHz',
                        _data.cpuTemp, const Color(0xFF00f0ff)),
                    const SizedBox(height: 4),
                    _buildInfoRow('GPU', '${_data.gpuUsage.toStringAsFixed(1)}%',
                        '${_data.gpuFreq.toStringAsFixed(2)} GHz',
                        _data.gpuTemp, const Color(0xFFff00ff)),
                    const SizedBox(height: 4),
                    _buildNetworkRow(),
                    const SizedBox(height: 4),
                    _buildBatteryRow(),
                    const SizedBox(height: 10),
                    _buildCpuMiniBars(),
                    const SizedBox(height: 8),
                    _buildThrottleStatus(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF00f0ff).withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00f0ff).withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: _throttleColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: _throttleColor.withOpacity(0.4), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'NEXUS',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w900,
              color: Color(0xFF00f0ff), fontFamily: 'monospace',
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            child: const Icon(Icons.remove, color: Colors.white70, size: 18),
            onTap: _toggleExpand,
          ),
          const SizedBox(width: 12),
          GestureDetector(
            child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
            onTap: () => FlutterOverlayWindow.closeOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildFpsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${_data.fps}',
          style: TextStyle(
            fontSize: 42, fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
            color: _data.fps >= 120
                ? const Color(0xFF00ff41)
                : _data.fps >= 60
                    ? const Color(0xFF00f0ff)
                    : Colors.amber,
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 6, left: 4),
          child: Text('FPS', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold,
            color: Colors.grey, fontFamily: 'monospace',
          )),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String usage, String freq, double temp, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 3)],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(label, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold,
              color: color, fontFamily: 'monospace',
            )),
          ),
          Expanded(
            child: Text(usage, style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: Colors.white, fontFamily: 'monospace',
            )),
          ),
          Text(freq, style: TextStyle(
            fontSize: 9, color: Colors.grey.shade500, fontFamily: 'monospace',
          )),
          const SizedBox(width: 8),
          Text('${temp.toStringAsFixed(0)}°C', style: TextStyle(
            fontSize: 9, fontFamily: 'monospace',
            color: temp > 72 ? Colors.amber : Colors.grey.shade500,
          )),
        ],
      ),
    );
  }

  Widget _buildNetworkRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF00ff41).withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi, size: 12, color: Colors.grey),
          const SizedBox(width: 8),
          Text('${_data.ping.toStringAsFixed(0)}ms', style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: Colors.white, fontFamily: 'monospace',
          )),
          const Spacer(),
          Text('\u{2193} ${_data.downloadSpeed.toStringAsFixed(1)} MB/s', style: const TextStyle(
            fontSize: 9, color: Color(0xFF00f0ff), fontFamily: 'monospace',
          )),
          const SizedBox(width: 8),
          Text('\u{2191} ${_data.uploadSpeed.toStringAsFixed(1)} MB/s', style: const TextStyle(
            fontSize: 9, color: Color(0xFFff00ff), fontFamily: 'monospace',
          )),
        ],
      ),
    );
  }

  Widget _buildBatteryRow() {
    final battLevel = _data.batteryLevel;
    final battTemp = _data.batteryTemp;
    final battColor = battLevel > 20 ? const Color(0xFF00ff41) : Colors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: battColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.battery_std, size: 12, color: Colors.grey),
          const SizedBox(width: 8),
          Text('${battLevel.toStringAsFixed(0)}%', style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600,
            color: battColor, fontFamily: 'monospace',
          )),
          const Spacer(),
          Text('${battTemp.toStringAsFixed(1)}°C', style: const TextStyle(
            fontSize: 9, color: Colors.grey, fontFamily: 'monospace',
          )),
        ],
      ),
    );
  }

  Widget _buildCpuMiniBars() {
    if (_cores.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CORE LOAD', style: TextStyle(
          fontSize: 8, color: Colors.grey, fontFamily: 'monospace', letterSpacing: 1,
        )),
        const SizedBox(height: 4),
        Wrap(
          spacing: 3,
          runSpacing: 3,
          children: _cores.map((core) {
            final usage = core.frequency > 0
                ? (core.frequency / core.maxFrequency).clamp(0.0, 1.0)
                : 0.0;
            return Container(
              width: 18,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF00f0ff).withOpacity(0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      width: 18,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                        gradient: LinearGradient(
                          begin: Alignment.top,
                          end: Alignment.bottom,
                          colors: [
                            const Color(0xFF00f0ff).withOpacity(0.0),
                            const Color(0xFF00f0ff).withOpacity(usage * 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThrottleStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _throttleColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _throttleColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.thermostat, size: 12, color: _throttleColor),
          const SizedBox(width: 6),
          Text(
            'THERMAL: ${_data.throttleStatus.toUpperCase()}',
            style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.bold,
              fontFamily: 'monospace', letterSpacing: 1,
              color: _throttleColor,
            ),
          ),
        ],
      ),
    );
  }
}
