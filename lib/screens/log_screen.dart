import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../data/game_log.dart';
import '../data/token_library.dart';

class LogScreen extends StatefulWidget {
  final GameLog gameLog;
  final double? rotationAngle;
  final VoidCallback? onUndo;
  final List<String> playerNames;

  const LogScreen({super.key, 
    required this.gameLog,
    this.rotationAngle,
    this.onUndo,
    required this.playerNames,
  });

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {

  Color _getPlayerColor(int index) {
    return index == 0 ? Color.fromARGB(255, 40, 63, 136) : Color.fromARGB(255, 165, 72, 47);
  }

  String _getPlayerName(int index) {
    return widget.playerNames[index];
  }

  Widget _buildPlayerBadge(int index) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPlayerColor(index),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        widget.playerNames[index].length <= 3 ? widget.playerNames[index] : widget.playerNames[index].substring(0, 3),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0),
      ),
    );
  }

  Color _getCategoryColor(int? categoryIndex, {bool undone = false}) {
    if (undone) return Colors.grey;
    if (categoryIndex == null) return Colors.white70;
    switch (TokenCategory.values[categoryIndex]) {
      case TokenCategory.debuffAura: return Colors.purpleAccent;
      case TokenCategory.boonAura: return Colors.lightBlueAccent;
      case TokenCategory.ally: return Colors.orange;
      case TokenCategory.item: return Color(0xFFD2A679);
    }
  }

  Widget _buildRichDescription(LogEntry entry) {
    final playerColor = _getPlayerColor(entry.playerIndex);
    final playerName = _getPlayerName(entry.playerIndex);
    final bool isUndone = entry.undone;
    final brightness = Theme.of(context).brightness;
    final Color textColor = isUndone ? Colors.grey : (brightness == Brightness.dark ? Colors.white70 : Colors.black87);
    final Color pColor = isUndone ? Colors.grey : playerColor;
    final TextDecoration? decoration = isUndone ? TextDecoration.lineThrough : null;
    final String fontFamily = Theme.of(context).textTheme.bodyMedium?.fontFamily ?? 'Sedan';
    final Color gainColor = isUndone ? Colors.grey : Color(0xFF66DE93);
    final Color lostColor = isUndone ? Colors.grey : Colors.red;

    List<TextSpan> spans;

    switch (entry.type) {
      case LogEventType.healthChange:
        final Color valueColor = entry.value > 0 ? gainColor : lostColor;
        if (entry.value > 0) {
          spans = [
            TextSpan(text: playerName, style: TextStyle(color: pColor, fontWeight: FontWeight.bold, decoration: decoration)),
            TextSpan(text: ' gained ', style: TextStyle(color: textColor, decoration: decoration)),
            TextSpan(text: '${entry.value}', style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, decoration: decoration)),
            TextSpan(text: ' health', style: TextStyle(color: valueColor, decoration: decoration)),
          ];
        } else {
          spans = [
            TextSpan(text: playerName, style: TextStyle(color: pColor, fontWeight: FontWeight.bold, decoration: decoration)),
            TextSpan(text: ' lost ', style: TextStyle(color: textColor, decoration: decoration)),
            TextSpan(text: '${entry.value.abs()}', style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, decoration: decoration)),
            TextSpan(text: ' health', style: TextStyle(color: valueColor, decoration: decoration)),
          ];
        }
        break;
      case LogEventType.tokenAdded:
        final tokenName = entry.undoData?['name'] as String? ?? entry.description.replaceAll(' added', '');
        final category = entry.undoData?['category'] as int?;
        final Color tokenColor = _getCategoryColor(category, undone: isUndone);
        String verb = 'gained';
        String suffix = '';
        if (category != null) {
          switch (TokenCategory.values[category]) {
            case TokenCategory.boonAura:
              verb = 'gained';
              break;
            case TokenCategory.debuffAura:
              verb = 'was inflicted with';
              break;
            case TokenCategory.item:
              verb = 'acquired';
              break;
            case TokenCategory.ally:
              verb = 'gained';
              suffix = ' as an ally';
              break;
          }
        }
        spans = [
          TextSpan(text: playerName, style: TextStyle(color: pColor, fontWeight: FontWeight.bold, decoration: decoration)),
          TextSpan(text: ' $verb ', style: TextStyle(color: textColor, decoration: decoration)),
          TextSpan(text: '1 ', style: TextStyle(color: tokenColor, fontWeight: FontWeight.bold, decoration: decoration)),
          TextSpan(text: tokenName, style: TextStyle(color: tokenColor, fontWeight: FontWeight.bold, decoration: decoration)),
          TextSpan(text: suffix, style: TextStyle(color: textColor, decoration: decoration)),
        ];
        break;
      case LogEventType.tokenDestroyed:
        final tokenName = entry.undoData?['name'] as String? ?? entry.description.replaceAll(' destroyed', '');
        final category = entry.undoData?['category'] as int?;
        final Color tokenColor = _getCategoryColor(category, undone: isUndone);
        spans = [
          TextSpan(text: playerName, style: TextStyle(color: pColor, fontWeight: FontWeight.bold, decoration: decoration)),
          TextSpan(text: '\'s ', style: TextStyle(color: pColor, decoration: decoration)),
          TextSpan(text: tokenName, style: TextStyle(color: tokenColor, fontWeight: FontWeight.bold, decoration: decoration)),
          TextSpan(text: ' was destroyed', style: TextStyle(color: textColor, decoration: decoration)),
        ];
        break;
      case LogEventType.tokenCountChange:
        final tokenName = entry.undoData?['name'] as String? ?? entry.description;
        final category = entry.undoData?['category'] as int?;
        final Color tokenColor = _getCategoryColor(category, undone: isUndone);
        final int count = entry.value.abs();
        final bool isAlly = category != null && TokenCategory.values[category] == TokenCategory.ally;
        if (entry.value > 0) {
          spans = [
            TextSpan(text: playerName, style: TextStyle(color: pColor, fontWeight: FontWeight.bold, decoration: decoration)),
            TextSpan(text: ' gained ', style: TextStyle(color: textColor, decoration: decoration)),
            TextSpan(text: '$count ', style: TextStyle(color: tokenColor, fontWeight: FontWeight.bold, decoration: decoration)),
            TextSpan(text: tokenName, style: TextStyle(color: tokenColor, fontWeight: FontWeight.bold, decoration: decoration)),
            if (isAlly) TextSpan(text: count == 1 ? ' as an ally' : ' as allies', style: TextStyle(color: textColor, decoration: decoration)),
          ];
        } else {
          spans = [
            TextSpan(text: playerName, style: TextStyle(color: pColor, fontWeight: FontWeight.bold, decoration: decoration)),
            TextSpan(text: ' lost ', style: TextStyle(color: textColor, decoration: decoration)),
            TextSpan(text: '$count ', style: TextStyle(color: tokenColor, fontWeight: FontWeight.bold, decoration: decoration)),
            TextSpan(text: tokenName, style: TextStyle(color: tokenColor, fontWeight: FontWeight.bold, decoration: decoration)),
          ];
        }
        break;
      case LogEventType.allyHealthChange:
        final tokenName = entry.undoData?['name'] as String? ?? entry.description.replaceAll(' health', '');
        final Color allyColor = isUndone ? Colors.grey : Colors.orange;
        final Color valueColor = entry.value > 0 ? gainColor : lostColor;
        if (entry.value > 0) {
          spans = [
            TextSpan(text: tokenName, style: TextStyle(color: allyColor, fontWeight: FontWeight.bold, decoration: decoration)),
            TextSpan(text: ' gained ', style: TextStyle(color: textColor, decoration: decoration)),
            TextSpan(text: '${entry.value}', style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, decoration: decoration)),
            TextSpan(text: ' health', style: TextStyle(color: valueColor, decoration: decoration)),
          ];
        } else {
          spans = [
            TextSpan(text: tokenName, style: TextStyle(color: allyColor, fontWeight: FontWeight.bold, decoration: decoration)),
            TextSpan(text: ' lost ', style: TextStyle(color: textColor, decoration: decoration)),
            TextSpan(text: '${entry.value.abs()}', style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, decoration: decoration)),
            TextSpan(text: ' health', style: TextStyle(color: valueColor, decoration: decoration)),
          ];
        }
        break;
      case LogEventType.phaseChange:
        spans = [
          TextSpan(text: entry.description, style: TextStyle(color: textColor, decoration: decoration)),
        ];
        break;
      case LogEventType.tokenActivated:
        spans = [
          TextSpan(text: entry.description, style: TextStyle(color: textColor, decoration: decoration)),
        ];
        break;
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: 13, height: 1.3, fontFamily: fontFamily),
        children: spans,
      ),
    );
  }

  String _formatLogAsText() {
    final buffer = StringBuffer();
    buffer.writeln('=== TableTop Token Tracker - Game Log ===');
    buffer.writeln('');
    for (final entry in widget.gameLog.entries) {
      final player = widget.playerNames[entry.playerIndex];
      final time = entry.timestamp;
      final phase = entry.phase != null ? ' [${entry.phase}]' : '';
      String detail = entry.description;
      if (entry.type == LogEventType.healthChange ||
          entry.type == LogEventType.allyHealthChange ||
          entry.type == LogEventType.tokenCountChange) {
        final sign = entry.value > 0 ? '+' : '';
        detail = '${entry.description} $sign${entry.value}';
      }
      buffer.writeln('$time | $player$phase | $detail');
    }
    buffer.writeln('');
    buffer.writeln('========================================');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final reversedEntries = widget.gameLog.entries.reversed.toList();

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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.gameLog.entries.isNotEmpty) ...[
                    IconButton(
                      icon: Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _formatLogAsText()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Log copied to clipboard'), duration: Duration(seconds: 2)),
                        );
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.share, size: 20),
                      onPressed: () {
                        Share.share(_formatLogAsText());
                      },
                    ),
                  ],
                  if (widget.onUndo != null)
                    IconButton(
                      icon: Icon(Icons.undo, color: Colors.blue),
                      onPressed: () {
                        widget.onUndo!();
                        setState(() {});
                      },
                    ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
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
                      return ListTile(
                        dense: true,
                        leading: _buildPlayerBadge(entry.playerIndex),
                        title: _buildRichDescription(entry),
                        subtitle: Text(
                          '${entry.timestamp}${entry.phase != null ? ' • ${entry.phase}' : ''}',
                          style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'CormorantGaramond'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}