import 'token_library.dart';

class ActiveToken {
  final String name;
  final TokenCategory category;
  final DestroyTrigger? destroyTrigger;
  int count;
  int? health;
  int? maxHealth;
  int turnPlayed;
  int playerPlayed;
  int phasePlayed;

  ActiveToken({
    required this.name,
    required this.category,
    this.destroyTrigger,
    this.count = 1,
    this.health,
    this.maxHealth,
    this.turnPlayed = 0,
    this.playerPlayed = 0,
    this.phasePlayed = 0,
  });
}
