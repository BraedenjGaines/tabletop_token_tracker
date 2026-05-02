import 'package:flutter/foundation.dart';
import '../data/active_token.dart';
import '../data/armor_slot_state.dart';
import '../data/game_log.dart';
import '../data/token_library.dart';

/// Result of removing a token, returned to the caller so they can log it.
class RemovedToken {
  final ActiveToken token;
  final int index;
  const RemovedToken({required this.token, required this.index});
}

/// Result of a phase advance. Reports what changed so the caller can react
/// (logging, animations, etc.).
class PhaseAdvanceResult {
  /// Tokens auto-destroyed by this advance.
  final List<({int playerIndex, ActiveToken token, int formerIndex})> destroyedTokens;
  /// True if this advance wrapped the turn (active player flipped).
  final bool turnWrapped;
  /// State before the advance.
  final int prevTurn;
  final int prevPhase;
  final int prevActivePlayer;

  const PhaseAdvanceResult({
    required this.destroyedTokens,
    required this.turnWrapped,
    required this.prevTurn,
    required this.prevPhase,
    required this.prevActivePlayer,
  });
}

/// Source of truth for the live state of a match.
///
/// Owns mutable game state and exposes mutators that emit change notifications.
/// Knows nothing about widgets, contexts, or rendering.
class MatchState extends ChangeNotifier {
  MatchState({
    required int playerCount,
    required int startingLife,
    required int phaseCount,
    required int armorSlotsPerPlayer,
  })  : _playerHealth = List<int>.filled(playerCount, startingLife),
        _playerTokens = List<List<ActiveToken>>.generate(playerCount, (_) => []),
        _playerPitch = List<int>.filled(playerCount, 0),
        _playerAP = List<int>.filled(playerCount, 0),
        _playerArmor = List<List<ArmorSlotState>>.generate(
          playerCount,
          (_) => List<ArmorSlotState>.generate(
              armorSlotsPerPlayer, (_) => ArmorSlotState()),
        ),
        _startingLife = startingLife,
        _playerCount = playerCount,
        _phaseCount = phaseCount,
        _armorSlotsPerPlayer = armorSlotsPerPlayer;

  final int _playerCount;
  final int _startingLife;
  final int _phaseCount;
  final int _armorSlotsPerPlayer;

  // --- Game log ---
  final GameLog gameLog = GameLog();

  void clearLog() {
    gameLog.clear();
    notifyListeners();
  }

  void addLogEntry(LogEntry entry) {
    gameLog.addEntry(entry);
    notifyListeners();
  }

  void removeLogEntryAt(int index) {
    if (index < 0 || index >= gameLog.entries.length) return;
    gameLog.entries.removeAt(index);
    notifyListeners();
  }

  int get playerCount => _playerCount;

  // --- Player health ---
  List<int> _playerHealth;
  List<int> get playerHealth => List.unmodifiable(_playerHealth);
  int healthOf(int playerIndex) => _playerHealth[playerIndex];

  int applyHealthDelta(int playerIndex, int delta) {
    final int newHealth = (_playerHealth[playerIndex] + delta).clamp(-99, 99);
    final int actualDelta = newHealth - _playerHealth[playerIndex];
    if (actualDelta == 0) return 0;
    _playerHealth[playerIndex] = newHealth;
    notifyListeners();
    return actualDelta;
  }

  void reverseHealthDelta(int playerIndex, int delta) {
    _playerHealth[playerIndex] -= delta;
    notifyListeners();
  }

  // --- Tokens ---
  List<List<ActiveToken>> _playerTokens;
  List<ActiveToken> tokensOf(int playerIndex) =>
      List.unmodifiable(_playerTokens[playerIndex]);
  List<ActiveToken> rawTokensOf(int playerIndex) => _playerTokens[playerIndex];

  void addToken(int playerIndex, ActiveToken token) {
    _playerTokens[playerIndex].add(token);
    notifyListeners();
  }

  void insertToken(int playerIndex, int index, ActiveToken token) {
    if (index >= _playerTokens[playerIndex].length) {
      _playerTokens[playerIndex].add(token);
    } else {
      _playerTokens[playerIndex].insert(index, token);
    }
    notifyListeners();
  }

  ActiveToken? removeTokenAt(int playerIndex, int index) {
    if (index < 0 || index >= _playerTokens[playerIndex].length) return null;
    final removed = _playerTokens[playerIndex].removeAt(index);
    notifyListeners();
    return removed;
  }

  bool removeLastTokenByName(int playerIndex, String name) {
    final idx = _playerTokens[playerIndex].lastIndexWhere((t) => t.name == name);
    if (idx < 0) return false;
    _playerTokens[playerIndex].removeAt(idx);
    notifyListeners();
    return true;
  }

  bool incrementCountOfDormantToken(
    int playerIndex,
    String name, {
    required bool Function(ActiveToken token, int playerIndex) isTriggering,
  }) {
    final tokens = _playerTokens[playerIndex];
    final idx = tokens.indexWhere((t) =>
        t.name == name && !isTriggering(t, playerIndex));
    if (idx < 0) return false;
    tokens[idx].count++;
    notifyListeners();
    return true;
  }

  void mutateTokenCount(int playerIndex, String name, int delta) {
    for (final t in _playerTokens[playerIndex]) {
      if (t.name == name) {
        t.count += delta;
        break;
      }
    }
    notifyListeners();
  }

  void setTokenCount(int playerIndex, ActiveToken token, int newCount) {
    token.count = newCount;
    notifyListeners();
  }

  void setTokenHealth(int playerIndex, ActiveToken token, int newHealth) {
    token.health = newHealth;
    notifyListeners();
  }

  void mutateAllyHealth(int playerIndex, String name, int delta) {
    for (final t in _playerTokens[playerIndex]) {
      if (t.name == name) {
        t.health = (t.health ?? 0) + delta;
        break;
      }
    }
    notifyListeners();
  }

  bool hasTokensInCategory(int playerIndex, TokenCategory category) {
    return _playerTokens[playerIndex].any((t) => t.category == category);
  }

  // --- Phase / turn / active player ---
  int _activePlayer = 0;
  int _currentPhase = 0;
  int _turnCount = 0;

  int get activePlayer => _activePlayer;
  int get currentPhase => _currentPhase;
  int get turnCount => _turnCount;

  /// Sets the active player at game start (after the first-turn chooser).
  /// Resets the chosen player's AP to 1 to mark turn 0 ready.
  void setInitialActivePlayer(int playerIndex) {
    _activePlayer = playerIndex;
    _playerAP[playerIndex] = 1;
    notifyListeners();
  }

  /// Advances the phase. If the current phase is the last, wraps to phase 0,
  /// flips the active player, increments the turn counter, resets the
  /// previously-active player's pitch and AP to 0, and sets the new active
  /// player's AP to 1. Then runs auto-destroy if [autoDestroyEnabled] is true.
  PhaseAdvanceResult advancePhase({required bool autoDestroyEnabled}) {
    final int prevTurn = _turnCount;
    final int prevPhase = _currentPhase;
    final int prevActive = _activePlayer;
    bool turnWrapped = false;

    if (_currentPhase < _phaseCount - 1) {
      _currentPhase++;
    } else {
      _currentPhase = 0;
      _playerPitch[_activePlayer] = 0;
      _playerAP[_activePlayer] = 0;
      _activePlayer = _activePlayer == 0 ? 1 : 0;
      _playerAP[_activePlayer] = 1;
      _turnCount++;
      turnWrapped = true;
    }

    final destroyed = _checkAutoDestroyInternal(
      enabled: autoDestroyEnabled,
      prevTurn: prevTurn,
      prevPhase: prevPhase,
      prevActive: prevActive,
    );

    notifyListeners();

    return PhaseAdvanceResult(
      destroyedTokens: destroyed,
      turnWrapped: turnWrapped,
      prevTurn: prevTurn,
      prevPhase: prevPhase,
      prevActivePlayer: prevActive,
    );
  }

  /// Retreats one phase if possible. Does not run auto-destroy and does not
  /// flip active player or turn count.
  void retreatPhase() {
    if (_currentPhase > 0) {
      _currentPhase--;
      notifyListeners();
    }
  }

  // --- AP / Pitch ---
  List<int> _playerPitch;
  List<int> _playerAP;

  int pitchOf(int playerIndex) => _playerPitch[playerIndex];
  int apOf(int playerIndex) => _playerAP[playerIndex];

  void setPitch(int playerIndex, int value) {
    _playerPitch[playerIndex] = value.clamp(0, 99);
    notifyListeners();
  }

  void setAP(int playerIndex, int value) {
    _playerAP[playerIndex] = value.clamp(0, 99);
    notifyListeners();
  }

  // --- Armor ---
  List<List<ArmorSlotState>> _playerArmor;

  ArmorSlotState armorSlot(int playerIndex, int slotIndex) =>
      _playerArmor[playerIndex][slotIndex];

  void incrementArmor(int playerIndex, int slotIndex) {
    _playerArmor[playerIndex][slotIndex].increment();
    notifyListeners();
  }

  void decrementArmor(int playerIndex, int slotIndex) {
    _playerArmor[playerIndex][slotIndex].decrement();
    notifyListeners();
  }

  void destroyArmor(int playerIndex, int slotIndex) {
    _playerArmor[playerIndex][slotIndex].destroy();
    notifyListeners();
  }

  // --- Auto-destroy & trigger logic ---

  static bool _isLater(int aTurn, int aPhase, int bTurn, int bPhase) {
    if (aTurn != bTurn) return aTurn > bTurn;
    return aPhase > bPhase;
  }

  static int? _triggerPhaseFor(
      ActiveToken t, int playerIndex, int activePlayerIdx) {
    if (t.destroyTrigger == null) return null;
    final bool isOwnerActive = playerIndex == activePlayerIdx;
    switch (t.destroyTrigger!) {
      case DestroyTrigger.startOfYourTurn:
        return isOwnerActive ? 0 : null;
      case DestroyTrigger.startOfOpponentTurn:
        return isOwnerActive ? null : 0;
      case DestroyTrigger.beginningOfActionPhase:
        return isOwnerActive ? 1 : null;
      case DestroyTrigger.beginningOfEndPhase:
        return isOwnerActive ? 2 : null;
    }
  }

  static bool isActivatedAt(
      ActiveToken t, int playerIndex, int turn, int phase, int activePlayerIdx) {
    if (t.destroyTrigger == null) return false;
    final int? triggerPhase = _triggerPhaseFor(t, playerIndex, activePlayerIdx);
    if (triggerPhase == null) return false;
    if (phase != triggerPhase) return false;
    return _isLater(turn, phase, t.turnPlayed, t.phasePlayed);
  }

  /// True iff the token is activated *right now* (under current state).
  bool isActivatedNow(ActiveToken t, int playerIndex) {
    return isActivatedAt(t, playerIndex, _turnCount, _currentPhase, _activePlayer);
  }

  static bool _shouldAutoRemoveOnAdvance(
    ActiveToken t,
    int playerIndex, {
    required int prevTurn,
    required int prevPhase,
    required int prevActive,
    required int turn,
    required int phase,
    required int activePlayerIdx,
  }) {
    if (t.destroyTrigger == null) return false;
    final bool wasActivated =
        isActivatedAt(t, playerIndex, prevTurn, prevPhase, prevActive);
    if (!wasActivated) return false;
    final bool stillActivated =
        isActivatedAt(t, playerIndex, turn, phase, activePlayerIdx);
    return !stillActivated;
  }

  List<({int playerIndex, ActiveToken token, int formerIndex})> _checkAutoDestroyInternal({
    required bool enabled,
    required int prevTurn,
    required int prevPhase,
    required int prevActive,
  }) {
    final removed = <({int playerIndex, ActiveToken token, int formerIndex})>[];
    if (!enabled) return removed;

    for (int pi = 0; pi < _playerCount; pi++) {
      final toRemove = <ActiveToken>[];
      for (final t in _playerTokens[pi]) {
        final shouldRemove = t.count <= 0 ||
            _shouldAutoRemoveOnAdvance(
              t,
              pi,
              prevTurn: prevTurn,
              prevPhase: prevPhase,
              prevActive: prevActive,
              turn: _turnCount,
              phase: _currentPhase,
              activePlayerIdx: _activePlayer,
            );
        if (shouldRemove) toRemove.add(t);
      }
      for (final t in toRemove) {
        final idx = _playerTokens[pi].indexOf(t);
        _playerTokens[pi].remove(t);
        removed.add((playerIndex: pi, token: t, formerIndex: idx));
      }
    }

    return removed;
  }

  // --- Reset ---
  void resetAll() {
    _playerHealth = List<int>.filled(_playerCount, _startingLife);
    _playerTokens = List<List<ActiveToken>>.generate(_playerCount, (_) => []);
    _playerPitch = List<int>.filled(_playerCount, 0);
    _playerAP = List<int>.filled(_playerCount, 0);
    _playerArmor = List<List<ArmorSlotState>>.generate(
      _playerCount,
      (_) => List<ArmorSlotState>.generate(
          _armorSlotsPerPlayer, (_) => ArmorSlotState()),
    );
    _activePlayer = 0;
    _currentPhase = 0;
    _turnCount = 0;
    gameLog.clear();
    notifyListeners();
  }
}