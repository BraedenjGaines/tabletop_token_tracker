import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Display mode for damage feedback.
enum DamageDisplayMode {
  /// Numbers float upward and fade out (multiple visible at once).
  cascading,
  /// A single accumulating total appears next to the health number, fading
  /// after a short idle period.
  totals,
}

/// Single in-flight floating number.
class FloatingNumber {
  final int value;
  final AnimationController controller;
  final int playerIndex;
  final double arcDirection;
  final double spawnOffset;

  FloatingNumber({
    required this.value,
    required this.controller,
    required this.playerIndex,
    required this.arcDirection,
    required this.spawnOffset,
  });
}

/// Single in-flight totals display.
class TotalsDisplay {
  final int value;
  final AnimationController controller;
  TotalsDisplay({required this.value, required this.controller});
}

/// Owns the animation state for damage feedback.
///
/// Notifies listeners only when the *set* of active floaters changes
/// (spawn/dispose), not on every animation tick. Per-frame redraws are handled
/// by [AnimatedBuilder] subscriptions inside the rendering widgets.
class FloatingDamageController extends ChangeNotifier {
  FloatingDamageController({required TickerProvider vsync}) : _vsync = vsync;

  final TickerProvider _vsync;

  // Cascading mode state
  final List<FloatingNumber> _floaters = [];
  int _floatSpawnIndex = 0;

  // Accumulator (used by both modes): running totals per (player, sign).
  // Resets to zero after 2s of inactivity per key.
  final Map<String, int> _accumulatorValues = {};
  final Map<String, Timer> _accumulatorTimers = {};

  // Totals mode state
  final Map<String, TotalsDisplay> _totals = {};
  final Map<String, Timer> _totalsTimers = {};

  static String _key(int playerIndex, bool negative) =>
      '${playerIndex}_${negative ? 'neg' : 'pos'}';

  /// Records a damage/heal delta for a player. Spawns either a cascading
  /// floater or updates the totals display, depending on [mode].
  void spawnDelta(int playerIndex, int delta, DamageDisplayMode mode) {
    if (delta == 0) return;
    final bool negative = delta < 0;
    final String key = _key(playerIndex, negative);

    // Update running accumulator for this (player, sign).
    _accumulatorValues[key] = (_accumulatorValues[key] ?? 0) + delta;
    _accumulatorTimers[key]?.cancel();
    _accumulatorTimers[key] = Timer(const Duration(seconds: 2), () {
      _accumulatorValues.remove(key);
      _accumulatorTimers.remove(key);
    });

    final int currentTotal = _accumulatorValues[key]!;

    switch (mode) {
      case DamageDisplayMode.cascading:
        _spawnFloater(playerIndex, currentTotal, negative);
        break;
      case DamageDisplayMode.totals:
        _updateTotals(key, currentTotal);
        break;
    }
  }

  void _spawnFloater(int playerIndex, int value, bool negative) {
    const spawnPoints = [-10.0, 0.0, 10.0];
    final spawnOffset = spawnPoints[_floatSpawnIndex % 3];
    _floatSpawnIndex++;

    final baseDir = negative ? -1.0 : 1.0;
    final arcDir = (_floatSpawnIndex % 2 == 0) ? baseDir : -baseDir;

    final controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: _vsync,
    );

    final floater = FloatingNumber(
      value: value,
      controller: controller,
      playerIndex: playerIndex,
      arcDirection: arcDir,
      spawnOffset: spawnOffset,
    );

    _floaters.add(floater);
    notifyListeners();

    controller.forward().then((_) {
      _floaters.remove(floater);
      controller.dispose();
      notifyListeners();
    });
  }

  void _updateTotals(String key, int value) {
    _totals[key]?.controller.dispose();
    final controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: _vsync,
    );
    _totals[key] = TotalsDisplay(value: value, controller: controller);
    controller.forward();

    _totalsTimers[key]?.cancel();
    _totalsTimers[key] = Timer(const Duration(seconds: 3), () {
      _totals[key]?.controller.dispose();
      _totals.remove(key);
      _totalsTimers.remove(key);
      notifyListeners();
    });

    notifyListeners();
  }

  /// Floaters belonging to one side of one player. Read by the rendering
  /// widget; mutating this list externally is undefined.
  Iterable<FloatingNumber> floatersFor(int playerIndex, {required bool negative}) {
    return _floaters.where((f) =>
        f.playerIndex == playerIndex &&
        (negative ? f.value < 0 : f.value > 0));
  }

  TotalsDisplay? totalsFor(int playerIndex, {required bool negative}) {
    return _totals[_key(playerIndex, negative)];
  }

  /// Clears all in-flight state without disposing controllers (callers must
  /// ensure they're not in use). Used by reset.
  void clear() {
    for (final f in _floaters) {
      f.controller.dispose();
    }
    _floaters.clear();
    for (final t in _accumulatorTimers.values) {
      t.cancel();
    }
    _accumulatorValues.clear();
    _accumulatorTimers.clear();
    for (final td in _totals.values) {
      td.controller.dispose();
    }
    _totals.clear();
    for (final t in _totalsTimers.values) {
      t.cancel();
    }
    _totalsTimers.clear();
    _floatSpawnIndex = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    clear();
    super.dispose();
  }
}

/// Renders the cascading floaters for one side of one player.
class FloatingNumbersSide extends StatelessWidget {
  final FloatingDamageController controller;
  final int playerIndex;
  final bool negative;

  const FloatingNumbersSide({
    super.key,
    required this.controller,
    required this.playerIndex,
    required this.negative,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final floaters = controller.floatersFor(playerIndex, negative: negative).toList();
        if (floaters.isEmpty) return const SizedBox.shrink();
        return IgnorePointer(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final f in floaters)
                AnimatedBuilder(
                  animation: f.controller,
                  builder: (context, child) {
                    final t = f.controller.value;
                    final opacity = (1.0 - t).clamp(0.0, 1.0);
                    final yOffset = -80 * t;
                    final xOffset = f.spawnOffset + (25 * sin(t * pi) * f.arcDirection);
                    return Transform.translate(
                      offset: Offset(xOffset, yOffset),
                      child: Opacity(
                        opacity: opacity,
                        child: Text(
                          f.value > 0 ? '+${f.value}' : '${f.value}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Inter',
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Renders the totals-mode display for one side of one player.
class TotalsDisplaySide extends StatelessWidget {
  final FloatingDamageController controller;
  final int playerIndex;
  final bool negative;

  const TotalsDisplaySide({
    super.key,
    required this.controller,
    required this.playerIndex,
    required this.negative,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final td = controller.totalsFor(playerIndex, negative: negative);
        if (td == null) return const SizedBox.shrink();
        return IgnorePointer(
          child: AnimatedBuilder(
            animation: td.controller,
            builder: (context, _) {
              final t = td.controller.value;
              final opacity = t < 0.5 ? 1.0 : (1.0 - ((t - 0.5) * 2.0)).clamp(0.0, 1.0);
              return Opacity(
                opacity: opacity,
                child: Text(
                  negative ? '${td.value}' : '+${td.value}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Inter',
                    color: Colors.black,
                    height: 1.0,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}