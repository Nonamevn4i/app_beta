import 'package:flutter/material.dart';

class AiAdvisor extends StatefulWidget {
  final String advice;
  final bool isLoading;
  final VoidCallback onRefresh;
  const AiAdvisor({super.key, required this.advice, required this.isLoading, required this.onRefresh});

  @override
  State<AiAdvisor> createState() => _AiAdvisorState();
}

class _AiAdvisorState extends State<AiAdvisor> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
  }

  @override
  void dispose() { _pulseController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFa855f7).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFa855f7).withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AnimatedBuilder(animation: _pulseController, builder: (context, child) => Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFa855f7), Color(0xFFec4899)]),
              boxShadow: [BoxShadow(color: const Color(0xFFa855f7).withOpacity(0.5 + _pulseController.value * 0.4), blurRadius: 6)],
            ),
          )),
          const SizedBox(width: 8),
          Text('GEMINI ADVISOR', style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontFamily: 'monospace', letterSpacing: 2, fontWeight: FontWeight.bold)),
          if (widget.isLoading) const Padding(padding: EdgeInsets.only(left: 8), child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFa855f7)))),
        ]),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.04), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.06))),
          child: Text('"${widget.advice}"', style: TextStyle(fontSize: 11, color: Colors.grey.shade300, fontStyle: FontStyle.italic, height: 1.5)),
        ),
        const SizedBox(height: 10),
        Row(children: [_tag('Diagnostic', const Color(0xFFa855f7)), const SizedBox(width: 6), _tag('AI Inference', Colors.grey)]),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: widget.isLoading ? null : widget.onRefresh,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              backgroundColor: const Color(0xFFa855f7).withOpacity(0.1),
              side: BorderSide(color: const Color(0xFFa855f7).withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(widget.isLoading ? 'ANALYZING...' : 'REFRESH ANALYSIS', style: const TextStyle(fontSize: 9, color: Color(0xFFc084fc), fontFamily: 'monospace', letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
    child: Text(text.toUpperCase(), style: TextStyle(fontSize: 8, color: color.withOpacity(0.8), fontFamily: 'monospace', fontWeight: FontWeight.bold, letterSpacing: 1)),
  );
}
