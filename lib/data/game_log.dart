enum LogEventType {
  healthChange,
  tokenAdded,
  tokenDestroyed,
  tokenActivated,
  tokenCountChange,
  allyHealthChange,
  phaseChange,
}

class LogEntry {
  final int playerIndex;
  final LogEventType type;
  final String description;
  int value;
  final String timestamp;
  final int? turn;
  final String? phase;
  final Map<String, dynamic>? undoData;
  bool undone;

  LogEntry({
    required this.playerIndex,
    required this.type,
    required this.description,
    this.value = 0,
    required this.timestamp,
    this.turn,
    this.phase,
    this.undoData,
    this.undone = false,
  });
}

class GameLog {
  final List<LogEntry> entries = [];

  DateTime? _lastEntryTime;

  void addEntry(LogEntry entry) {
    final now = DateTime.now();
    if (entries.isNotEmpty && _isStackable(entry.type)) {
      final last = entries.last;
      final withinTime = _lastEntryTime != null && now.difference(_lastEntryTime!).inSeconds < 10;
      if (last.playerIndex == entry.playerIndex &&
          last.type == entry.type &&
          last.description == entry.description &&
          last.phase == entry.phase &&
          withinTime) {
        last.value += entry.value;
        if (last.value == 0) {
          entries.removeLast();
        }
        _lastEntryTime = now;
        return;
      }
    }
    _lastEntryTime = now;
    entries.add(entry);
  }
  bool _isStackable(LogEventType type) {
    return type == LogEventType.healthChange ||
        type == LogEventType.tokenCountChange ||
        type == LogEventType.allyHealthChange;
  }
  void clear() {
    entries.clear();
  }
}