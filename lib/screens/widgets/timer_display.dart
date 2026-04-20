import 'package:flutter/material.dart';

class TimerDisplay extends StatelessWidget {
  final int secondsRemaining;
  final bool isRunning;
  final bool flashOn;
  final VoidCallback onReset;
  final VoidCallback onToggle;

  const TimerDisplay({
    super.key,
    required this.secondsRemaining,
    required this.isRunning,
    this.flashOn = true,
    required this.onReset,
    required this.onToggle,
  });

  String _format() {
    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _color() {
    if (secondsRemaining <= 0) return flashOn ? Color(0xFFE53935) : Color(0xFF3A3A3A);
    if (secondsRemaining <= 300) return Color(0xFFE53935);
    if (secondsRemaining <= 600) return Colors.orange;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(onTap: onToggle, child: Icon(isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20)),
        SizedBox(width: 27),
        Text(_format(), style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _color(), fontFeatures: [FontFeature.tabularFigures()])),
        SizedBox(width: 27),
        GestureDetector(onTap: onReset, child: Icon(Icons.replay, color: Colors.white, size: 18)),
      ]),
    );
  }
}
