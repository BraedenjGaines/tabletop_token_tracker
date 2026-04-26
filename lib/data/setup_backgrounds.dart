import 'dart:math';
import 'package:flutter/services.dart' show rootBundle, AssetManifest;

/// Resolves the list of available setup screen backgrounds from the asset
/// manifest at runtime. This way you can add or remove images in
/// assets/images/backgrounds/ without changing code.
class SetupBackgrounds {
  static const String _directory = 'assets/images/backgrounds/';

  static List<String>? _cached;
  static String? _sessionPick;

  /// Returns the full list of registered setup background asset paths.
  /// Results are cached per app launch.
  static Future<List<String>> all() async {
    if (_cached != null) return _cached!;
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      _cached = manifest
          .listAssets()
          .where((key) => key.startsWith(_directory))
          .where((key) => key.toLowerCase().contains('_setup.'))
          .where((key) =>
              key.toLowerCase().endsWith('.jpg') ||
              key.toLowerCase().endsWith('.jpeg') ||
              key.toLowerCase().endsWith('.png'))
          .toList()
        ..sort();
      // ignore: avoid_print
      print('SetupBackgrounds found ${_cached!.length} images: $_cached');
    } catch (e) {
      // ignore: avoid_print
      print('SetupBackgrounds failed to load manifest: $e');
      _cached = const [];
    }
    return _cached!;
  }

  /// Returns the background chosen for this app session. Picks one at random
  /// the first time it is called, then returns the same path for the rest of
  /// the session. Returns null if no backgrounds are registered.
  static Future<String?> sessionPick() async {
    if (_sessionPick != null) return _sessionPick;
    final list = await all();
    if (list.isEmpty) return null;
    _sessionPick = list[Random().nextInt(list.length)];
    return _sessionPick;
  }
}