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

  LogEntry({
    required this.playerIndex,
    required this.type,
    required this.description,
    this.value = 0,
    required this.timestamp,
    this.turn,
    this.phase,
  });
}

class GameLog {
  final List<LogEntry> entries = [];

  void addEntry(LogEntry entry) {
    if (entries.isNotEmpty) {
      final last = entries.last;
      if (last.playerIndex == entry.playerIndex &&
          last.type == entry.type &&
          last.description == entry.description &&
          _isStackable(entry.type)) {
        last.value += entry.value;
        if (last.value == 0) {
          entries.removeLast();
        }
        return;
      }
    }
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