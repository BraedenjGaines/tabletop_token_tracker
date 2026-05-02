import 'package:flutter/material.dart';

/// Overlay shown at game start: lets the user pick who goes first directly,
/// or request a dice roll.
///
/// Calls [onDirectChoice] with the player index that should go first when the
/// user taps either "Goes First" button. Calls [onRequestDice] when the user
/// wants to use dice instead.
class FirstTurnChooser extends StatelessWidget {
  final List<String> playerNames;
  final void Function(int playerIndex) onDirectChoice;
  final VoidCallback onRequestDice;

  const FirstTurnChooser({
    super.key,
    required this.playerNames,
    required this.onDirectChoice,
    required this.onRequestDice,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Player 0 — rotated 180° to face the top player.
            RotatedBox(
              quarterTurns: 2,
              child: _GoesFirstButton(
                name: playerNames[0],
                onPressed: () => onDirectChoice(0),
              ),
            ),
            const SizedBox(height: 32),
            _DiceButton(onPressed: onRequestDice),
            const SizedBox(height: 32),
            // Player 1 — normal orientation.
            _GoesFirstButton(
              name: playerNames[1],
              onPressed: () => onDirectChoice(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoesFirstButton extends StatelessWidget {
  final String name;
  final VoidCallback onPressed;

  const _GoesFirstButton({required this.name, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 60, 143, 63),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: '$name\n'),
            const TextSpan(text: 'Goes First'),
          ]),
          textAlign: TextAlign.center,
          softWrap: true,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _DiceButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DiceButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[700],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.casino, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Roll Dice',
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}