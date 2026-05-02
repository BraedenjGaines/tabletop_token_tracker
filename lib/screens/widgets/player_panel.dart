import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../../data/active_token.dart';
import '../../data/app_assets.dart';
import '../../data/hero_library.dart';
import '../../data/token_library.dart';
import '../../providers/game_settings_provider.dart';
import '../../state/match_state.dart';
import 'hero_image.dart';

/// Renders one player's panel: hero art background, tap halves for health
/// changes, token chips, optional pitch counter and add-token button.
///
/// The panel does not know about overlays. When the user taps a category chip
/// or the add-token button, the panel calls [onCategoryTap] / [onAddTokenTap]
/// and the parent decides what to render in response.
///
/// Floating-damage rendering is delegated via [floatingNumbersBuilder] so the
/// parent can own the animation system without leaking it down.
class PlayerPanel extends StatelessWidget {
  final int playerIndex;
  final String heroId;
  final List<HeroData> customHeroes;
  final bool showTurnTracker;

  /// Called with the actual delta applied to player health (clamped).
  final void Function(int actualDelta) onHealthChanged;

  /// Called when the user taps the add-token button.
  final VoidCallback onAddTokenTap;

  /// Called when the user taps a category chip.
  final void Function(TokenCategory category) onCategoryTap;

  /// Predicate used to render the "triggering" highlight on chips. Provided by
  /// the parent because it depends on phase/turn context held there.
  final bool Function(ActiveToken token, int playerIndex) isTokenTriggering;

  /// Returns the floating-damage widget for the given side. Parent owns the
  /// animation controllers; this builder simply asks "render whatever floaters
  /// belong on the negative or positive side of player [playerIndex]."
  final Widget Function({required bool negative}) floatingNumbersBuilder;

  /// Same idea for the totals-mode display.
  final Widget Function({required bool negative}) totalsDisplayBuilder;

  const PlayerPanel({
    super.key,
    required this.playerIndex,
    required this.heroId,
    required this.customHeroes,
    required this.showTurnTracker,
    required this.onHealthChanged,
    required this.onAddTokenTap,
    required this.onCategoryTap,
    required this.isTokenTriggering,
    required this.floatingNumbersBuilder,
    required this.totalsDisplayBuilder,
  });

  // --- Display constants ---
  static const double _panelButtonWidth = 0.26;
  static const double _panelButtonHeight = 0.13;
  static const double _panelInsetWithResource = 0.22;
  static const double _panelInsetNoResource = 0.365;

  static const Map<TokenCategory, String> _categoryNames = {
    TokenCategory.ally: 'Allies',
    TokenCategory.item: 'Items',
    TokenCategory.boonAura: 'Buffs',
    TokenCategory.debuffAura: 'Debuffs',
  };

  static const Map<TokenCategory, Color> _categoryColors = {
    TokenCategory.ally: Color.fromARGB(255, 160, 106, 25),
    TokenCategory.boonAura: Color.fromARGB(255, 41, 134, 177),
    TokenCategory.debuffAura: Color.fromARGB(255, 120, 32, 136),
    TokenCategory.item: Color(0xFFD2A679),
  };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GameSettingsProvider>();
    final double screenWidth = MediaQuery.of(context).size.width;

    return Consumer<MatchState>(
      builder: (context, state, _) {
        final bool isActive = showTurnTracker && state.activePlayer == playerIndex;
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isActive ? Colors.blue : Colors.black,
              width: 3,
            ),
          ),
          child: Stack(
            children: [
              _buildHeroBackground(),
              _buildHealthTapZones(context, settings),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, -0.85),
                  child: Consumer<MatchState>(
                    builder: (context, _, _) => _buildTokenChips(context),
                  ),
                ),
              ),
              _buildHealthDisplay(context),
              if (settings.addTokenButtonEnabled)
                _buildAddTokenButton(settings, screenWidth),
              if (settings.resourceTrackerSetting == 0 ||
                  settings.resourceTrackerSetting == 2)
                _buildPitchPositioned(settings, screenWidth),
            ],
          ),
        );
      },
    );
  }

  // --- Hero background ---
  Widget _buildHeroBackground() {
    return Positioned.fill(
      child: Builder(
        builder: (context) {
          final hero = [...heroLibrary, ...customHeroes].cast<HeroData?>().firstWhere(
                (h) => h?.id == heroId,
                orElse: () => null,
              );
          if (hero == null) {
            return Container(color: Colors.grey[900]);
          }
          if (hero.customImagePath != null) {
            return Image.file(
              File(hero.customImagePath!),
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
            );
          }
          return HeroImage(
            hero: hero,
            fit: BoxFit.cover,
            placeholder: Container(color: Colors.grey[900]),
          );
        },
      ),
    );
  }

  // --- Health tap zones (left = -1, right = +1) ---
  Widget _buildHealthTapZones(BuildContext context, GameSettingsProvider settings) {
    return Positioned.fill(
      child: Row(
        children: [
          _buildTapHalf(
            context,
            settings,
            delta: -1,
            label: '-',
            border: Border(right: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 0.5)),
          ),
          _buildTapHalf(
            context,
            settings,
            delta: 1,
            label: '+',
            border: Border(left: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 0.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildTapHalf(
    BuildContext context,
    GameSettingsProvider settings, {
    required int delta,
    required String label,
    required Border border,
  }) {
    final double blurSigma = settings.frostedGlass ? 5.0 : 0.0;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          final state = context.read<MatchState>();
          final actualDelta = state.applyHealthDelta(playerIndex, delta);
          if (actualDelta == 0) return;
          onHealthChanged(actualDelta);
        },
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                border: border,
              ),
              child: Align(
                alignment: const Alignment(0, -0.1),
                child: Stack(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 3
                          ..color = Colors.black,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Inter',
                        color: Colors.black.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Health display with floating numbers ---
  Widget _buildHealthDisplay(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: const Alignment(0, -0.1),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Consumer<MatchState>(
                builder: (context, state, _) {
                  final h = state.healthOf(playerIndex);
                  return Stack(
                    children: [
                      Text(
                        '$h',
                        style: TextStyle(
                          fontSize: 106,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                          foreground: Paint()
                            ..style = PaintingStyle.stroke
                            ..strokeWidth = 4
                            ..color = Colors.black,
                        ),
                      ),
                      Text(
                        '$h',
                        style: const TextStyle(
                          fontSize: 106,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                          color: Color.fromARGB(255, 14, 21, 22),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Positioned(top: -1, left: -20, child: totalsDisplayBuilder(negative: true)),
              Positioned(top: -1, right: -20, child: totalsDisplayBuilder(negative: false)),
              Positioned(left: -44, top: 0, child: floatingNumbersBuilder(negative: true)),
              Positioned(right: -44, top: 0, child: floatingNumbersBuilder(negative: false)),
            ],
          ),
        ),
      ),
    );
  }

  // --- Token chips ---
  Widget _buildTokenChips(BuildContext context) {
    final state = context.read<MatchState>();
    final byCategory = <TokenCategory, List<int>>{};
    final tokens = state.rawTokensOf(playerIndex);
    for (int i = 0; i < tokens.length; i++) {
      byCategory.putIfAbsent(tokens[i].category, () => []).add(i);
    }
    const order = [
      TokenCategory.boonAura,
      TokenCategory.debuffAura,
      TokenCategory.item,
      TokenCategory.ally,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = constraints.maxWidth * 0.8;
        final double chipWidth = totalWidth / 4;
        final double chipHeight = chipWidth * 1.2;

        return SizedBox(
          height: chipHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var cat in order)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: byCategory.containsKey(cat)
                      ? _buildCategoryChip(
                          cat,
                          tokens.where((t) => t.category == cat).fold<int>(0, (sum, t) => sum + t.count),
                          chipWidth,
                          chipHeight,
                        )
                      : SizedBox(width: chipWidth, height: chipHeight),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(TokenCategory cat, int count, double chipWidth, double chipHeight) {
    return Builder(
      builder: (context) {
        final tokens = context.read<MatchState>().rawTokensOf(playerIndex);
        final hasTriggering = tokens
            .where((t) => t.category == cat)
            .any((t) => isTokenTriggering(t, playerIndex));

        return GestureDetector(
          onTap: () => onCategoryTap(cat),
          child: Container(
            width: chipWidth,
            height: chipHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: hasTriggering
                  ? Border.all(color: Colors.amber, width: 2)
                  : Border.all(color: Colors.black.withValues(alpha: 0.3), width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: -5, right: -5, top: -5, bottom: -5,
                  child: Image.asset(
                    AppAssets.addTokenButton,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[800]),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _categoryColors[cat]!.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    if (hasTriggering) const Icon(Icons.flash_on, size: 12, color: Colors.amber),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Stack(
                        children: [
                          Text(
                            _categoryNames[cat] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 1.5
                                ..color = Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _categoryNames[cat] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Stack(
                          children: [
                            Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 2
                                  ..color = Colors.black,
                              ),
                            ),
                            Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Add-token button (positioned) ---
  Widget _buildAddTokenButton(GameSettingsProvider settings, double screenWidth) {
    final bool hasPitch = settings.resourceTrackerSetting == 0 || settings.resourceTrackerSetting == 2;
    final double inset = (hasPitch ? _panelInsetWithResource : _panelInsetNoResource) * screenWidth;
    return Positioned(
      left: playerIndex == 1 ? null : inset,
      right: playerIndex == 1 ? inset : null,
      bottom: 0, top: 0,
      child: Align(
        alignment: const Alignment(0, 0.50),
        child: GestureDetector(
          onTap: onAddTokenTap,
          child: Container(
            width: screenWidth * _panelButtonWidth,
            height: screenWidth * _panelButtonHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: -10, right: -10, top: -10, bottom: -10,
                  child: Image.asset(
                    AppAssets.addTokenButton,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.black.withValues(alpha: 0.5)),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const Icon(Icons.add, size: 28, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Pitch counter (positioned) ---
  Widget _buildPitchPositioned(GameSettingsProvider settings, double screenWidth) {
    final double inset = (settings.addTokenButtonEnabled ? _panelInsetWithResource : _panelInsetNoResource) * screenWidth;
    return Positioned(
      left: playerIndex == 1 ? inset : null,
      right: playerIndex == 0 ? inset : null,
      bottom: 0, top: 0,
      child: IgnorePointer(
        ignoring: false,
        child: Align(
          alignment: const Alignment(0, 0.50),
          child: Consumer<MatchState>(
            builder: (context, _, _) => _buildPitchCounter(context, screenWidth: screenWidth),
          ),
        ),
      ),
    );
  }

  Widget _buildPitchCounter(BuildContext context, {required double screenWidth}) {
    final state = context.read<MatchState>();
    const double iconSize = 20.0;
    const double numSize = 22.0;
    final int pitchValue = state.pitchOf(playerIndex);

    Color pitchColor;
    if (pitchValue >= 3) {
      pitchColor = const Color.fromARGB(255, 60, 163, 247);
    } else if (pitchValue == 2) {
      pitchColor = const Color.fromARGB(255, 241, 229, 117);
    } else if (pitchValue == 1) {
      pitchColor = const Color.fromARGB(255, 190, 50, 40);
    } else {
      pitchColor = Colors.white;
    }

    final String pitchIconPath = AppAssets.pitchIconFor(pitchValue);

    final List<Shadow> iconShadows = const [
      Shadow(color: Colors.black, offset: Offset(0, 0), blurRadius: 0),
    ];
    final List<Shadow> numberShadows = [
      Shadow(color: Colors.black, offset: const Offset(-1.5, 0), blurRadius: 0),
      Shadow(color: Colors.black, offset: const Offset(1.5, 0), blurRadius: 0),
      Shadow(color: Colors.black, offset: const Offset(0, -1.5), blurRadius: 0),
      Shadow(color: Colors.black, offset: const Offset(0, 1.5), blurRadius: 0),
    ];

    return Container(
      width: screenWidth * _panelButtonWidth,
      height: screenWidth * _panelButtonHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Transform.scale(
              scale: 1.3,
              child: Image.asset(
                pitchIconPath,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => Container(color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final v = state.pitchOf(playerIndex);
                      if (v > 0) state.setPitch(playerIndex, v - 1);
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.remove, size: iconSize, color: pitchColor, shadows: iconShadows),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      final v = state.pitchOf(playerIndex);
                      if (v < 99) state.setPitch(playerIndex, v + 1);
                    },
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(Icons.add, size: iconSize, color: pitchColor, shadows: iconShadows),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: Text(
              '$pitchValue',
              style: TextStyle(
                fontSize: numSize,
                fontWeight: FontWeight.bold,
                color: pitchColor,
                height: 1.0,
                shadows: numberShadows,
              ),
            ),
          ),
        ],
      ),
    );
  }
}