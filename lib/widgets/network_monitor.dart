import 'package:flutter/material.dart';

class NetworkMonitor extends StatelessWidget {
  final double downloadSpeed;
  final double uploadSpeed;
  final double ping;
  const NetworkMonitor({super.key, required this.downloadSpeed, required this.uploadSpeed, required this.ping});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4fc3f7).withOpacity(0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.wifi, color: Color(0xFF4fc3f7), size: 14), const SizedBox(width: 6), Text('NETWORK', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'monospace', letterSpacing: 1.5))]),
        const SizedBox(height: 14),
        Row(children: [
          _netBlock('PING', '${ping.toStringAsFixed(0)}', 'ms', ping > 100 ? Colors.redAccent : const Color(0xFF00ff41)),
          const SizedBox(width: 12),
          _netBlock('DOWNLOAD', downloadSpeed.toStringAsFixed(1), 'MB/s', const Color(0xFF00f0ff)),
          const SizedBox(width: 12),
          _netBlock('UPLOAD', uploadSpeed.toStringAsFixed(1), 'MB/s', const Color(0xFFff00ff)),
        ]),
      ]),
    );
  }

  Widget _netBlock(String label, String value, String unit, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(8)),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 8, color: Colors.grey.shade600, fontFamily: 'monospace', letterSpacing: 1.2, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color, fontFamily: 'monospace')),
        Text(unit, style: TextStyle(fontSize: 9, color: color.withOpacity(0.6), fontFamily: 'monospace')),
      ]),
    ));
  }
}
