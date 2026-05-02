import '../data/token_library.dart';

/// What overlay (if any) is showing on a player's panel.
sealed class PlayerOverlay {
  const PlayerOverlay();
}

/// No overlay is showing for this player.
class NoOverlay extends PlayerOverlay {
  const NoOverlay();
}

/// The "add token" picker is showing for this player.
class AddTokenOverlay extends PlayerOverlay {
  const AddTokenOverlay();
}

/// The category management overlay is showing, scoped to one category.
class CategoryOverlay extends PlayerOverlay {
  final TokenCategory category;
  const CategoryOverlay(this.category);
}