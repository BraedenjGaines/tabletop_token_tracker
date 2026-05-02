import 'package:flutter/material.dart';
import 'dice_overlay.dart';
import 'first_turn_chooser.dart';

/// Coordinates the first-turn chooser and dice overlay at the start of a match.
///
/// Internally manages the transition between chooser → dice → done. Emits a
/// single [onFirstPlayerChosen] callback when the user has finalized their
/// choice. Renders nothing once the choice is finalized.
class MatchStartOverlays extends StatefulWidget {
  final List<String> playerNames;
  final void Function(int playerIndex) onFirstPlayerChosen;

  /// External signal to re-show the chooser (e.g. after Reset).
  final bool show;

  const MatchStartOverlays({
    super.key,
    required this.playerNames,
    required this.onFirstPlayerChosen,
    required this.show,
  });

  @override
  State<MatchStartOverlays> createState() => _MatchStartOverlaysState();
}

class _MatchStartOverlaysState extends State<MatchStartOverlays> {
  bool _showDiceOverlay = false;

  @override
  void didUpdateWidget(covariant MatchStartOverlays oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent re-shows the chooser (e.g. on reset), drop dice state.
    if (widget.show && !oldWidget.show) {
      setState(() => _showDiceOverlay = false);
    }
  }

  void _onDirectChoice(int playerIndex) {
    widget.onFirstPlayerChosen(playerIndex);
  }

  void _onRequestDice() {
    setState(() => _showDiceOverlay = true);
  }

  void _onDiceChoice(int winner, bool goFirst) {
    final int chosen = goFirst ? winner : (winner == 0 ? 1 : 0);
    widget.onFirstPlayerChosen(chosen);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();

    if (_showDiceOverlay) {
      return DiceOverlay(
        playerNames: widget.playerNames,
        onChoice: _onDiceChoice,
      );
    }

    return FirstTurnChooser(
      playerNames: widget.playerNames,
      onDirectChoice: _onDirectChoice,
      onRequestDice: _onRequestDice,
    );
  }
}