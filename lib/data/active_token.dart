import 'token_library.dart';

class ActiveToken {
  final String name;
  final TokenCategory category;
  /// Sub-categorization for auras; null for non-aura categories.
  final AuraType? auraType;
  final DestroyTrigger? destroyTrigger;
  final String? customImagePath;
  int count;
  int? health;
  int? maxHealth;
  int turnPlayed;
  int playerPlayed;
  int phasePlayed;

  ActiveToken({
    required this.name,
    required this.category,
    this.auraType,
    this.destroyTrigger,
    this.customImagePath,
    this.count = 1,
    this.health,
    this.maxHealth,
    this.turnPlayed = 0,
    this.playerPlayed = 0,
    this.phasePlayed = 0,
  });
}

/// Display bucket resolution for in-play tokens. Same logic as the matching
/// extension on [TokenData] — both delegate to [resolveDisplayBucket].
extension ActiveTokenDisplayBucket on ActiveToken {
  TokenDisplayBucket get displayBucket =>
      resolveDisplayBucket(category, auraType);
}