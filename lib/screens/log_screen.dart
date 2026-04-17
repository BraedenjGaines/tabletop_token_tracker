import 'package:flutter/material.dart';
import '../data/game_log.dart';

class LogScreen extends StatelessWidget {
  final GameLog gameLog;
  final double? rotationAngle;

  const LogScreen({super.key, 
    required this.gameLog,
    this.rotationAngle,
  });

  String _getPlayerLabel(int index) {
    return 'Player ${index + 1}';
  }

  IconData _getEventIcon(LogEventType type) {
    switch (type) {
      case LogEventType.healthChange:
        return Icons.favorite;
      case LogEventType.tokenAdded:
        return Icons.add_circle;
      case LogEventType.tokenDestroyed:
        return Icons.remove_circle;
      case LogEventType.tokenActivated:
        return Icons.flash_on;
      case LogEventType.tokenCountChange:
        return Icons.numbers;
      case LogEventType.allyHealthChange:
        return Icons.shield;
      case LogEventType.phaseChange:
        return Icons.arrow_forward;
    }
  }

  Color _getEventColor(LogEventType type) {
    switch (type) {
      case LogEventType.healthChange:
        return Colors.red;
      case LogEventType.tokenAdded:
        return Colors.green;
      case LogEventType.tokenDestroyed:
        return Colors.orange;
      case LogEventType.tokenActivated:
        return Colors.amber;
      case LogEventType.tokenCountChange:
        return Colors.blue;
      case LogEventType.allyHealthChange:
        return Colors.purple;
      case LogEventType.phaseChange:
        return Colors.grey;
    }
  }

  String _formatValue(LogEntry entry) {
    if (entry.type == LogEventType.healthChange ||
        entry.type == LogEventType.allyHealthChange ||
        entry.type == LogEventType.tokenCountChange) {
      return entry.value > 0 ? '+${entry.value}' : '${entry.value}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final reversedEntries = gameLog.entries.reversed.toList();

    return Container(
      padding: EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Game Log',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 8),
          Expanded(
            child: reversedEntries.isEmpty
                ? Center(child: Text('No events yet'))
                : ListView.builder(
                    itemCount: reversedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = reversedEntries[index];
                      final valueText = _formatValue(entry);

                      return ListTile(
                        dense: true,
                        leading: Icon(
                          _getEventIcon(entry.type),
                          color: _getEventColor(entry.type),
                          size: 20,
                        ),
                        title: Text(
                          entry.description,
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          '${entry.timestamp} • ${_getPlayerLabel(entry.playerIndex)}${entry.phase != null ? ' • ${entry.phase}' : ''}',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        trailing: valueText.isNotEmpty
                            ? Text(
                                valueText,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: entry.value > 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}