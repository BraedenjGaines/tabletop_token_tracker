import 'dart:async';
import 'package:flutter/material.dart';

class TimerDisplay extends StatefulWidget {
  final int secondsRemaining;
  final bool isRunning;
  final VoidCallback onReset;
  final VoidCallback onToggle;

  const TimerDisplay({
    super.key,
    required this.secondsRemaining,
    required this.isRunning,
    required this.onReset,
    required this.onToggle,
  });

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay> {
  Timer? _flashTimer;
  bool _flashOn = true;

  bool get _isExpired => widget.secondsRemaining <= 0;

  @override
  void didUpdateWidget(covariant TimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasExpired = oldWidget.secondsRemaining <= 0;
    if (_isExpired && !wasExpired) {
      _startFlash();
    } else if (!_isExpired && wasExpired) {
      _stopFlash();
    }
  }

  @override
  void initState() {
    super.initState();
    if (_isExpired) _startFlash();
  }

  void _startFlash() {
    _flashTimer?.cancel();
    setState(() => _flashOn = false);
    _flashTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _flashOn = !_flashOn);
    });
  }

  void _stopFlash() {
    _flashTimer?.cancel();
    _flashTimer = null;
    setState(() => _flashOn = true);
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  String _format() {
    final m = widget.secondsRemaining ~/ 60;
    final s = widget.secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _color() {
    if (_isExpired) return _flashOn ? const Color(0xFFE53935) : const Color(0xFF3A3A3A);
    if (widget.secondsRemaining <= 300) return const Color(0xFFE53935);
    if (widget.secondsRemaining <= 600) return Colors.orange;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 31),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(onTap: widget.onToggle, child: Icon(widget.isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 26)),
        const SizedBox(width: 27),
        Text(_format(), style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _color(), fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(width: 27),
        GestureDetector(onTap: widget.onReset, child: Icon(Icons.replay, color: Colors.white, size: 26)),
      ]),
    );
  }
}
