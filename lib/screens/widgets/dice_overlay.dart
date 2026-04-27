import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

class DiceOverlay extends StatefulWidget {
  final void Function(int winner, bool goFirst) onChoice;
  final List<String> playerNames;

  const DiceOverlay({super.key, required this.onChoice, required this.playerNames});

  @override
  State<DiceOverlay> createState() => _DiceOverlayState();
}

class _DiceOverlayState extends State<DiceOverlay> {
  bool _rolling = true;
  bool _finished = false;
  bool _showChoice = false;
  List<int> _p1Dice = [1, 1];
  List<int> _p2Dice = [1, 1];
  int _winner = 0;
  Timer? _timer;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _startRoll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRoll() {
    int tickCount = 0;
    _timer = Timer.periodic(Duration(milliseconds: 80), (timer) {
      setState(() {
        _p1Dice = [_random.nextInt(6) + 1, _random.nextInt(6) + 1];
        _p2Dice = [_random.nextInt(6) + 1, _random.nextInt(6) + 1];
      });
      tickCount++;
      if (tickCount >= 25) {
        timer.cancel();
        _finalize();
      }
    });
  }

  void _finalize() {
    int p1Total, p2Total;
    do {
      _p1Dice = [_random.nextInt(6) + 1, _random.nextInt(6) + 1];
      _p2Dice = [_random.nextInt(6) + 1, _random.nextInt(6) + 1];
      p1Total = _p1Dice[0] + _p1Dice[1];
      p2Total = _p2Dice[0] + _p2Dice[1];
    } while (p1Total == p2Total);
    setState(() { _rolling = false; _finished = true; _winner = p1Total > p2Total ? 0 : 1; });
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) setState(() { _showChoice = true; });
    });
  }

  IconData _dieIcon(int value) {
    switch (value) {
      case 1: return Icons.looks_one;
      case 2: return Icons.looks_two;
      case 3: return Icons.looks_3;
      case 4: return Icons.looks_4;
      case 5: return Icons.looks_5;
      case 6: return Icons.looks_6;
      default: return Icons.casino;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget choiceButtons = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => widget.onChoice(_winner, true),
          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 60, 143, 63), padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          child: Text('Go First', style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
        SizedBox(width: 24),
        ElevatedButton(
          onPressed: () => widget.onChoice(_winner, false),
          style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 52, 120, 175), padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          child: Text('Go Second', style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ],
    );

    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Column(children: [
        Expanded(child: RotatedBox(quarterTurns: 2, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.playerNames[0], style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Row(mainAxisSize: MainAxisSize.min, children: [Icon(_dieIcon(_p1Dice[0]), size: 64, color: Colors.white), SizedBox(width: 16), Icon(_dieIcon(_p1Dice[1]), size: 64, color: Colors.white)]),
          SizedBox(height: 8),
          Text('Total: ${_p1Dice[0] + _p1Dice[1]}', style: TextStyle(color: Colors.white70, fontSize: 18)),
          if (_finished && !_rolling) ...[SizedBox(height: 8), Text(_winner == 0 ? 'WINNER!' : '', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold))],
          if (_showChoice && _winner == 0) ...[SizedBox(height: 16), choiceButtons],
        ])))),
        Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(widget.playerNames[1], style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Row(mainAxisSize: MainAxisSize.min, children: [Icon(_dieIcon(_p2Dice[0]), size: 64, color: Colors.white), SizedBox(width: 16), Icon(_dieIcon(_p2Dice[1]), size: 64, color: Colors.white)]),
          SizedBox(height: 8),
          Text('Total: ${_p2Dice[0] + _p2Dice[1]}', style: TextStyle(color: Colors.white70, fontSize: 18)),
          if (_finished && !_rolling) ...[SizedBox(height: 8), Text(_winner == 1 ? 'WINNER!' : '', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold))],
          if (_showChoice && _winner == 1) ...[SizedBox(height: 16), choiceButtons],
        ]))),
      ]),
    );
  }
}
