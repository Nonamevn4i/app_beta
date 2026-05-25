import 'package:flutter/material.dart';

class BatteryStatus extends StatelessWidget {
  final double level;
  final double temperature;
  final int voltage;
  final String status;
  final bool charging;
  final String health;
  const BatteryStatus({
    super.key, required this.level, required this.temperature,
    this.voltage = 0, this.status = 'Unknown', this.charging = false, this.health = 'Good',
  });

  @override
  Widget build(BuildContext context) {
    final isLow = level < 20;
    final isHot = temperature > 42;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isLow ? Colors.redAccent.withOpacity(0.3) : Colors.green.withOpacity(0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(charging ? Icons.battery_charging_full : Icons.battery_full, color: isLow ? Colors.redAccent : Colors.greenAccent, size: 14),
          const SizedBox(width: 6),
          Text('POWER', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontFamily: 'monospace', letterSpacing: 1.5)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: charging ? Colors.green.withOpacity(0.15) : Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
            child: Text(status.toUpperCase(), style: TextStyle(fontSize: 8, color: charging ? Colors.greenAccent : Colors.grey.shade500, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(level.toStringAsFixed(0), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: isLow ? Colors.redAccent : Colors.greenAccent, fontFamily: 'monospace')),
          const Padding(padding: EdgeInsets.only(bottom: 4), child: Text('%', style: TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'monospace'))),
          const Spacer(),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${temperature.toStringAsFixed(1)}°C', style: TextStyle(fontSize: 12, color: isHot ? Colors.redAccent : Colors.grey.shade400, fontFamily: 'monospace')),
            if (voltage > 0) Text('${(voltage / 1000).toStringAsFixed(3)}V', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'monospace')),
          ]),
        ]),
        const SizedBox(height: 10),
        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: level / 100, backgroundColor: Colors.white.withOpacity(0.06), valueColor: AlwaysStoppedAnimation<Color>(isLow ? Colors.redAccent : charging ? Colors.greenAccent : Colors.green), minHeight: 6)),
      ]),
    );
  }
}
