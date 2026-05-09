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

  /// Replaces the hero with the same id. Preserves list position. Persists.
  /// Returns the updated list.
  static Future<List<HeroData>> update(HeroData hero) async {
    final heroes = await loadAll();
    final index = heroes.indexWhere((h) => h.id == hero.id);
    if (index < 0) {
      heroes.add(hero);
    } else {
      heroes[index] = hero;
    }
    await saveAll(heroes);
    return heroes;
  }

  // --- Schema ---
  // Centralized JSON shape. The schema supports both new format
  // (`talents: [int, int, ...]`) and legacy format (`talent: int`).

  static HeroData _fromMap(dynamic raw) {
    final map = raw as Map<String, dynamic>;
    return HeroData(
      id: map['id'] as String? ?? 'custom_unknown',
      name: map['name'] as String? ?? 'Unknown',
      heroClass: HeroClass.values[map['heroClass'] as int? ?? 0],
      talents: _talentsFromMap(map),
      isYoung: false,
      intellect: map['intellect'] as int? ?? 0,
      health: map['health'] as int? ?? 0,
      customImagePath: map['imagePath'] as String?,
      cardText: map['cardText'] as String? ?? '',
    );
  }

  /// Reads talents from either the new `talents` array or the legacy
  /// `talent` single-int field. Drops `HeroTalent.none` entries since the
  /// new model uses an empty list to mean "no talents."
  static List<HeroTalent> _talentsFromMap(Map<String, dynamic> map) {
    final raw = map['talents'];
    if (raw is List) {
      final result = <HeroTalent>[];
      for (final t in raw) {
        if (t is int && t >= 0 && t < HeroTalent.values.length) {
          final talent = HeroTalent.values[t];
          if (talent != HeroTalent.none) result.add(talent);
        }
      }
      return result.isEmpty ? [HeroTalent.none] : result;
    }
    // Legacy single-talent fallback.
    final legacyIdx = map['talent'] as int? ?? 0;
    if (legacyIdx >= 0 && legacyIdx < HeroTalent.values.length) {
      return [HeroTalent.values[legacyIdx]];
    }
    return [HeroTalent.none];
  }

  static Map<String, dynamic> _toMap(HeroData hero) {
    return {
      'id': hero.id,
      'name': hero.name,
      'heroClass': hero.heroClass.index,
      'talents': hero.talents.map((t) => t.index).toList(),
      'intellect': hero.intellect,
      'health': hero.health,
      'imagePath': hero.customImagePath,
      'cardText': hero.cardText,
    };
  }
}