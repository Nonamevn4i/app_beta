import 'package:flutter/material.dart';
import '../models/telemetry_model.dart';

class CpuBars extends StatelessWidget {
  final List<CpuCoreInfo> cores;
  final double totalUsage;
  const CpuBars({super.key, required this.cores, required this.totalUsage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00f0ff).withOpacity(0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.memory, color: Color(0xFF00f0ff), size: 14),
          const SizedBox(width: 6),
          Text('CPU CORES', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'monospace', letterSpacing: 1.5)),
          const Spacer(),
          Text('${totalUsage.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: Color(0xFF00f0ff), fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        ...List.generate(cores.length > 0 ? cores.length : 8, (i) => _coreBar(i)),
      ]),
    );
  }

  Widget _coreBar(int index) {
    final core = index < cores.length ? cores[index] : null;
    final freq = core?.frequency ?? 0;
    final maxFreq = core?.maxFrequency ?? 3200;
    final pct = maxFreq > 0 ? (freq / maxFreq) : 0.0;
    Color barColor = pct > 0.85 ? const Color(0xFFFF4500) : pct > 0.6 ? const Color(0xFFFFA500) : const Color(0xFF00f0ff);
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        SizedBox(width: 28, child: Text('C$index', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontFamily: 'monospace', fontWeight: FontWeight.bold))),
        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(2), child: LinearProgressIndicator(value: pct, backgroundColor: Colors.white.withOpacity(0.05), valueColor: AlwaysStoppedAnimation<Color>(barColor), minHeight: 8))),
        const SizedBox(width: 6),
        SizedBox(width: 48, child: Text('${freq}MHz', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontFamily: 'monospace'), textAlign: TextAlign.right)),
      ]),
    );
  }
}
