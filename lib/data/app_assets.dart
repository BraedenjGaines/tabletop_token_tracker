/// Centralized asset paths.
///
/// All bundled-asset string literals belong here. Adding a new asset to the
/// app means adding a constant in this class and adding the file to pubspec.
class AppAssets {
  AppAssets._();

  // --- UI ---
  static const String playButton = 'assets/images/ui/play_button.png';
  static const String addTokenButton = 'assets/images/ui/add_token_button.png';
  static const String fleshAndBloodLogo = 'assets/images/ui/flesh-and-blood_logo.png';
  static const String turnTrackerOverlay = 'assets/images/ui/turn_tracker_overlay.png';

  // --- Pitch icons ---
  static const String pitchValueZero = 'assets/images/ui/pitch_value_zero.png';
  static const String pitchValueOne = 'assets/images/ui/pitch_value_one.png';
  static const String pitchValueTwo = 'assets/images/ui/pitch_value_two.png';
  static const String pitchValueThree = 'assets/images/ui/pitch_value_three.png';

  /// Returns the pitch icon for a given value, capped at three.
  static String pitchIconFor(int pitchValue) {
    if (pitchValue >= 3) return pitchValueThree;
    if (pitchValue == 2) return pitchValueTwo;
    if (pitchValue == 1) return pitchValueOne;
    return pitchValueZero;
  }

  // --- Backgrounds ---
  static const String mapBackground = 'assets/images/backgrounds/map_background.jpg';

  // --- Armor (referenced from armor_slot_widget.dart's static list) ---
  static const String armorHelmet = 'assets/images/armor_helmet.png';
  static const String armorChest = 'assets/images/armor_chest.png';
  static const String armorGauntlet = 'assets/images/armor_gauntlet.png';
  static const String armorGreave = 'assets/images/armor_greave.png';
  static const List<String> armorSlots = [
    armorHelmet,
    armorChest,
    armorGauntlet,
    armorGreave,
  ];

  // --- Tokens ---
  /// Returns the asset path for a token's card-art image, given its id.
  static String tokenArtFor(String tokenId) =>
      'assets/images/tokens/${tokenId}_token.jpg';
}