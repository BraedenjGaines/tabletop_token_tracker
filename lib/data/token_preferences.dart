import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'token_library.dart';

class TokenPreferences {
  static const String _customTokensKey = 'customTokensFull_fab';
  static const String _favoritesKey = 'favoriteTokens_fab';
  static const String _legacyCustomTokensKey = 'customTokens_fab';

  /// Bumped when the persisted token schema changes. v1 was the original
  /// schema with categories {ally, item, boonAura, debuffAura}. v2 splits
  /// auras into a single category with an auraType sub-field and adds
  /// genericToken and landmark categories.
  static const int _schemaVersion = 2;

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<List<TokenData>> getCustomTokens() async {
    final prefs = await _getPrefs();
    final jsonList = prefs.getStringList(_customTokensKey) ?? [];
    return jsonList.map((json) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return _tokenFromMap(map);
    }).toList();
  }

  static Future<void> addCustomToken(TokenData token) async {
    final prefs = await _getPrefs();
    final jsonList = prefs.getStringList(_customTokensKey) ?? [];
    final exists = jsonList.any((json) {
      final map = jsonDecode(json);
      return map['name'] == token.name;
    });
    if (!exists) {
      jsonList.add(jsonEncode(_tokenToMap(token)));
      await prefs.setStringList(_customTokensKey, jsonList);
    }
  }

  static Future<void> removeCustomToken(String tokenName) async {
    final prefs = await _getPrefs();
    final jsonList = prefs.getStringList(_customTokensKey) ?? [];
    jsonList.removeWhere((json) {
      final map = jsonDecode(json);
      return map['name'] == tokenName;
    });
    await prefs.setStringList(_customTokensKey, jsonList);
    if (prefs.containsKey(_legacyCustomTokensKey)) {
      await prefs.remove(_legacyCustomTokensKey);
    }
  }

  /// Replaces a token. Matches the original by [originalName] (which may
  /// differ from token.name if the user renamed it). Preserves list position.
  static Future<void> updateCustomToken(
    String originalName,
    TokenData token,
  ) async {
    final prefs = await _getPrefs();
    final jsonList = prefs.getStringList(_customTokensKey) ?? [];
    final index = jsonList.indexWhere((json) {
      final map = jsonDecode(json);
      return map['name'] == originalName;
    });
    final encoded = jsonEncode(_tokenToMap(token));
    if (index < 0) {
      jsonList.add(encoded);
    } else {
      jsonList[index] = encoded;
    }
    await prefs.setStringList(_customTokensKey, jsonList);
  }

  static Future<List<String>> getFavorites() async {
    final prefs = await _getPrefs();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  static Future<void> toggleFavorite(String tokenName) async {
    final prefs = await _getPrefs();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    if (favorites.contains(tokenName)) {
      favorites.remove(tokenName);
    } else {
      favorites.add(tokenName);
    }
    await prefs.setStringList(_favoritesKey, favorites);
  }

  // --- Schema ---

  static Map<String, dynamic> _tokenToMap(TokenData token) {
    return {
      'schemaVersion': _schemaVersion,
      'name': token.name,
      'category': token.category.index,
      'auraType': token.auraType?.index,
      'destroyTrigger': token.destroyTrigger?.index,
      'health': token.health,
      'customImagePath': token.customImagePath,
      'cardText': token.cardText,
    };
  }

  /// Reads a token from a persisted map. Detects schema version and migrates
  /// old entries (v1) to the new shape (v2) on read.
  static TokenData _tokenFromMap(Map<String, dynamic> map) {
    final version = map['schemaVersion'] as int? ?? 1;
    if (version >= 2) {
      return TokenData(
        name: map['name'] as String,
        category: TokenCategory.values[map['category'] as int],
        auraType: map['auraType'] != null
            ? AuraType.values[map['auraType'] as int]
            : null,
        destroyTrigger: map['destroyTrigger'] != null
            ? DestroyTrigger.values[map['destroyTrigger'] as int]
            : null,
        health: map['health'] as int?,
        customImagePath: map['customImagePath'] as String?,
        cardText: map['cardText'] as String? ?? '',
      );
    }
    return _migrateV1(map);
  }

  /// Migrates a v1 persisted token to the v2 model.
  ///
  /// v1 categories (by index):
  ///   0: ally
  ///   1: item
  ///   2: boonAura  -> v2: aura + AuraType.buff
  ///   3: debuffAura -> v2: aura + AuraType.debuff
  static TokenData _migrateV1(Map<String, dynamic> map) {
    final oldIndex = map['category'] as int? ?? 0;
    TokenCategory newCategory;
    AuraType? newAuraType;
    switch (oldIndex) {
      case 0:
        newCategory = TokenCategory.ally;
      case 1:
        newCategory = TokenCategory.item;
      case 2:
        newCategory = TokenCategory.aura;
        newAuraType = AuraType.buff;
      case 3:
        newCategory = TokenCategory.aura;
        newAuraType = AuraType.debuff;
      default:
        // Unknown index — fall back to genericToken to avoid data loss.
        newCategory = TokenCategory.genericToken;
    }

    final isAura = newCategory == TokenCategory.aura;
    final isAlly = newCategory == TokenCategory.ally;

    return TokenData(
      name: map['name'] as String,
      category: newCategory,
      auraType: newAuraType,
      // Destroy trigger only applies to auras in v2; drop it for non-auras.
      destroyTrigger: isAura && map['destroyTrigger'] != null
          ? DestroyTrigger.values[map['destroyTrigger'] as int]
          : null,
      // Health only applies to allies in v2; drop it for non-allies.
      health: isAlly ? map['health'] as int? : null,
      customImagePath: map['customImagePath'] as String?,
    );
  }
}