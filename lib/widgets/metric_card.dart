import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final IconData? icon;
  final String? subtitle;
  final String status;
  final Widget? child;
  final Color? accentColor;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    this.icon,
    this.subtitle,
    this.status = 'Normal',
    this.child,
    this.accentColor,
  });

  Color get _borderColor {
    switch (status) {
      case 'Critical': return Colors.redAccent.withOpacity(0.6);
      case 'Warning': return Colors.amber.withOpacity(0.5);
      default: return accentColor?.withOpacity(0.25) ?? Colors.cyan.withOpacity(0.25);
    }
  }

  Color get _bgColor {
    switch (status) {
      case 'Critical': return Colors.red.withOpacity(0.08);
      case 'Warning': return Colors.amber.withOpacity(0.06);
      default: return Colors.white.withOpacity(0.03);
    }
  }

  Color get _valueColor {
    switch (status) {
      case 'Critical': return Colors.redAccent;
      case 'Warning': return Colors.amber;
      default: return accentColor ?? Colors.cyanAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(title.toUpperCase(), style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey.shade500, letterSpacing: 1.2))),
            if (status == 'Critical')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: Text('CRIT', style: TextStyle(fontSize: 8, color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
          ]),
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _valueColor, height: 1.1)),
            if (unit != null) ...[const SizedBox(width: 3), Padding(padding: const EdgeInsets.only(bottom: 2), child: Text(unit!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _valueColor.withOpacity(0.7), fontFamily: 'monospace')))],
          ]),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05)))),
              child: Row(children: [
                if (icon != null) ...[Icon(icon, color: _valueColor, size: 12), const SizedBox(width: 4)],
                Text(subtitle!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontFamily: 'monospace')),
              ]),
            ),
          ],
          if (child != null) ...[const SizedBox(height: 8), child!],
        ],
      ),
    );
  }
}
