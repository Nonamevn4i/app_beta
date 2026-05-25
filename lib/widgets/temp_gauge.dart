import 'package:flutter/material.dart';

class TempGauge extends StatelessWidget {
  final double cpuTemp;
  final double gpuTemp;
  final double batteryTemp;
  const TempGauge({super.key, required this.cpuTemp, required this.gpuTemp, required this.batteryTemp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.thermostat, color: Colors.amber, size: 14), const SizedBox(width: 6), Text('THERMALS', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'monospace', letterSpacing: 1.5))]),
        const SizedBox(height: 14),
        Row(children: [
          _tempBlock('CPU', cpuTemp, const Color(0xFF00f0ff)),
          const SizedBox(width: 12),
          _tempBlock('GPU', gpuTemp, const Color(0xFFff00ff)),
          const SizedBox(width: 12),
          _tempBlock('BAT', batteryTemp, Colors.amber),
        ]),
      ]),
    );
  }

  Widget _tempBlock(String label, double temp, Color color) {
    final isHot = temp > 75;
    return Expanded(child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isHot ? Colors.redAccent.withOpacity(0.4) : color.withOpacity(0.15)),
      ),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontFamily: 'monospace', letterSpacing: 1, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('${temp.toStringAsFixed(0)}°', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isHot ? Colors.redAccent : color, fontFamily: 'monospace')),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: temp.clamp(0, 100) / 100, backgroundColor: Colors.white.withOpacity(0.06), valueColor: AlwaysStoppedAnimation<Color>(isHot ? Colors.redAccent : color), minHeight: 4)),
      ]),
    ));
  }
}
