import 'package:flutter/material.dart';

class FpsDisplay extends StatefulWidget {
  final int fps;
  final double size;
  final VoidCallback? onToggleMinimize;

  const FpsDisplay({
    super.key,
    required this.fps,
    this.size = 100,
    this.onToggleMinimize,
  });

  @override
  State<FpsDisplay> createState() => _FpsDisplayState();
}

class _FpsDisplayState extends State<FpsDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _fpsColor {
    if (widget.fps >= 110) return const Color(0xFF00ff41);
    if (widget.fps >= 60) return const Color(0xFF00f0ff);
    if (widget.fps >= 30) return const Color(0xFFFFA500);
    return const Color(0xFFFF4500);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onToggleMinimize,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0a0a0f).withOpacity(0.85),
          border: Border.all(color: _fpsColor.withOpacity(0.5), width: 2),
          boxShadow: [BoxShadow(color: _fpsColor.withOpacity(0.3), blurRadius: 15, spreadRadius: 2)],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Text(
                  '${widget.fps}',
                  style: TextStyle(
                    fontSize: widget.size * 0.38,
                    fontWeight: FontWeight.w900,
                    color: _fpsColor.withOpacity(0.8 + _pulseController.value * 0.2),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Text('FPS', style: TextStyle(fontSize: 10, color: _fpsColor.withOpacity(0.6), fontFamily: 'monospace', letterSpacing: 2, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
