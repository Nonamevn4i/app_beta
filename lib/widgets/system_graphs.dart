import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/telemetry_model.dart';

class SystemGraphs extends StatelessWidget {
  final List<ChartDataPoint> data;
  const SystemGraphs({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        decoration: _boxDecor(),
        child: const Center(child: Text('AWAITING TELEMETRY...', style: TextStyle(color: Colors.grey, fontSize: 10, fontFamily: 'monospace', letterSpacing: 2))),
      );
    }
    final last = data.last;
    final cpuSpots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.cpu)).toList();
    final gpuSpots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.gpu)).toList();
    final fpsSpots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.fps.toDouble())).toList();

    return Container(
      height: 200, padding: const EdgeInsets.all(14), decoration: _boxDecor(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Text('${last.fps}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF00f0ff), fontFamily: 'monospace')),
            const Padding(padding: EdgeInsets.only(bottom: 4), child: Text(' FPS', style: TextStyle(fontSize: 11, color: Color(0xFF00f0ff), fontFamily: 'monospace', fontWeight: FontWeight.bold))),
          ]),
          Row(children: [
            _legendDot(const Color(0xFF00f0ff), 'CPU'),
            const SizedBox(width: 10),
            _legendDot(const Color(0xFFff00ff), 'GPU'),
            const SizedBox(width: 10),
            _legendDot(const Color(0xFF00ff41), 'FPS'),
          ]),
        ]),
        const SizedBox(height: 2),
        Text('FRAME TIME TELEMETRY (TARGET 6.1ms)', style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontFamily: 'monospace', letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Expanded(child: cpuSpots.length < 2
          ? const Center(child: Text('COLLECTING DATA...', style: TextStyle(color: Colors.grey, fontSize: 9)))
          : LineChart(LineChartData(
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 30, getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.04), strokeWidth: 1)),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minY: 0, maxY: 165,
              lineBarsData: [
                _buildLine(cpuSpots, const Color(0xFF00f0ff), 2),
                _buildLine(gpuSpots, const Color(0xFFff00ff), 2),
                _buildDashedLine(fpsSpots, const Color(0xFF00ff41), 1),
              ],
              lineTouchData: const LineTouchData(enabled: false),
            ))),
      ]),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color, double width) => LineChartBarData(
    spots: spots, isCurved: true, color: color, barWidth: width, isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
  );

  LineChartBarData _buildDashedLine(List<FlSpot> spots, Color color, double width) => LineChartBarData(
    spots: spots, isCurved: true, color: color, barWidth: width, isStrokeCapRound: true,
    dotData: const FlDotData(show: false), dashArray: [6, 4],
    belowBarData: const BarAreaData(show: false),
  );

  Widget _legendDot(Color color, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)])),
    const SizedBox(width: 4),
    Text(label, style: TextStyle(fontSize: 8, color: Colors.grey.shade500, fontFamily: 'monospace')),
  ]);

  BoxDecoration _boxDecor() => BoxDecoration(
    color: const Color(0xFF00f0ff).withOpacity(0.04),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFF00f0ff).withOpacity(0.15)),
  );
}
