import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'hero_library.dart';

/// Single source of truth for persisting user-created custom heroes.
///
/// Owns the JSON schema for the `'custom_heroes'` SharedPreferences key.
/// All callers reading or writing custom heroes must go through this class.
class CustomHeroRepository {
  static const String _key = 'custom_heroes';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Loads all custom heroes. Returns an empty list if none exist or if the
  /// persisted data is malformed.
  static Future<List<HeroData>> loadAll() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_key) ?? '[]';
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map(_fromMap).toList();
    } catch (_) {
      return [];
    }
  }

  /// Persists the entire list of custom heroes, replacing whatever was stored.
  static Future<void> saveAll(List<HeroData> heroes) async {
    final prefs = await _getPrefs();
    final list = heroes.map(_toMap).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  /// Adds a hero and persists. Returns the updated list.
  static Future<List<HeroData>> add(HeroData hero) async {
    final heroes = await loadAll();
    heroes.add(hero);
    await saveAll(heroes);
    return heroes;
  }

  /// Removes the hero with the given id and persists. Returns the updated list.
  static Future<List<HeroData>> removeById(String id) async {
    final heroes = await loadAll();
    heroes.removeWhere((h) => h.id == id);
    await saveAll(heroes);
    return heroes;
  }

  // --- Schema ---
  // Centralized JSON shape. Change here and only here if the schema evolves.

  static HeroData _fromMap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    return HeroData(
      id: map['id'] as String? ?? 'custom_unknown',
      name: map['name'] as String? ?? 'Unknown',
      heroClass: HeroClass.values[map['heroClass'] as int? ?? 0],
      talents: [HeroTalent.values[map['talent'] as int? ?? 0]],
      isYoung: false,
      intellect: 0,
      health: 0,
      customImagePath: map['imagePath'] as String?,
    );
  }

  static Map<String, dynamic> _toMap(HeroData hero) {
    return {
      'id': hero.id,
      'name': hero.name,
      'heroClass': hero.heroClass.index,
      // Existing schema stores a single 'talent' int, not a list. Preserve that
      // for backward compatibility — pull the first talent.
      'talent': hero.talents.isNotEmpty ? hero.talents.first.index : 0,
      'imagePath': hero.customImagePath,
    };
  }
}