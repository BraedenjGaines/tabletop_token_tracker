import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/app_assets.dart';
import '../../data/fab_phases.dart';
import '../../providers/game_settings_provider.dart';
import '../../state/match_state.dart';

/// The turn tracker bar rendered between the two player panels.
///
/// Renders the bar background image, the active player's name and current
/// phase, advance/retreat arrows, and (depending on the resource-tracker
/// setting) AP counters for each player.
///
/// State reads happen via Provider. Phase mutators are taken as callbacks
/// because they involve side effects beyond MatchState (logging, etc.) that
/// belong to the parent.
class TurnTrackerPanel extends StatelessWidget {
  final List<String> playerNames;
  final VoidCallback onAdvancePhase;
  final VoidCallback onRetreatPhase;

  const TurnTrackerPanel({
    super.key,
    required this.playerNames,
    required this.onAdvancePhase,
    required this.onRetreatPhase,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IgnorePointer(child: _background(context)),
        Consumer<MatchState>(
          builder: (context, _, _) => _controls(context),
        ),
      ],
    );
  }

  Widget _background(BuildContext context) {
    return Transform.flip(
      child: Image.asset(
        AppAssets.turnTrackerOverlay,
        width: MediaQuery.of(context).size.width * 2,
        fit: BoxFit.fitWidth,
      ),
    );
  }

  Widget _controls(BuildContext context) {
    final settings = context.watch<GameSettingsProvider>();
    final state = context.read<MatchState>();
    final int setting = settings.resourceTrackerSetting;
    final bool showAP = setting == 0 || setting == 1;

    final centerContent = RotatedBox(
      quarterTurns: state.activePlayer == 0 ? 2 : 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left, color: Color(0xFFF5E8C4), size: 20),
                onPressed: onRetreatPhase,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _activePlayerLabel(state.activePlayer),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF5E8C4),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fabPhases[state.currentPhase],
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFF5E8C4),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_right, color: Color(0xFFF5E8C4), size: 20),
                onPressed: onAdvancePhase,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );

    final body = showAP
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                RotatedBox(quarterTurns: 2, child: _APCounter(playerIndex: 0)),
                Expanded(child: centerContent),
                _APCounter(playerIndex: 1),
              ],
            ),
          )
        : centerContent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: body,
    );
  }

  String _activePlayerLabel(int activePlayer) {
    final name = playerNames[activePlayer];
    final shortName = name.length > 6 ? '${name.substring(0, 6)}..' : name;
    return "$shortName's Turn";
  }
}

class _APCounter extends StatelessWidget {
  final int playerIndex;
  const _APCounter({required this.playerIndex});

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchState>(
      builder: (context, state, _) {
        const double iconSize = 20.0;
        const double numSize = 22.0;
        const double labelSize = 10.0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                final v = state.apOf(playerIndex);
                if (v > 0) state.setAP(playerIndex, v - 1);
              },
              child: const Icon(Icons.remove, size: iconSize, color: Color(0xFFF5E8C4)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'AP',
                    style: TextStyle(
                      fontSize: labelSize,
                      color: Color(0xFFF5E8C4),
                      height: 1.0,
                      fontFamily: 'CormorantGaramond',
                    ),
                  ),
                  Text(
                    '${state.apOf(playerIndex)}',
                    style: const TextStyle(
                      fontSize: numSize,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF5E8C4),
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                final v = state.apOf(playerIndex);
                if (v < 99) state.setAP(playerIndex, v + 1);
              },
              child: const Icon(Icons.add, size: iconSize, color: Color(0xFFF5E8C4)),
            ),
          ],
        );
      },
    );
  }
}