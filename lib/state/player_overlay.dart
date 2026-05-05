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

/// The category management overlay is showing, scoped to one display bucket
/// (e.g. Buffs, Debuffs, Items). The bucket is the user-facing grouping; the
/// underlying [TokenCategory] of contained tokens may differ (auras share a
/// single category but split into buff/debuff buckets).
class CategoryOverlay extends PlayerOverlay {
  final TokenDisplayBucket bucket;
  const CategoryOverlay(this.bucket);
}