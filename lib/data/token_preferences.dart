import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'token_library.dart';

class TokenPreferences {
  static const String _customTokensKey = 'customTokensFull_fab';
  static const String _favoritesKey = 'favoriteTokens_fab';
  static const String _legacyCustomTokensKey = 'customTokens_fab';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<List<TokenData>> getCustomTokens() async {
    final prefs = await _getPrefs();
    final jsonList = prefs.getStringList(_customTokensKey) ?? [];
    return jsonList.map((json) {
      final map = jsonDecode(json);
      return TokenData(
        name: map['name'],
        category: TokenCategory.values[map['category']],
        destroyTrigger: map['destroyTrigger'] != null
            ? DestroyTrigger.values[map['destroyTrigger']]
            : null,
        health: map['health'],
        customImagePath: map['customImagePath'],
      );
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
      jsonList.add(jsonEncode({
        'name': token.name,
        'category': token.category.index,
        'destroyTrigger': token.destroyTrigger?.index,
        'health': token.health,
        'customImagePath': token.customImagePath,
      }));
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

    // Clean up legacy format if it exists.
    if (prefs.containsKey(_legacyCustomTokensKey)) {
      await prefs.remove(_legacyCustomTokensKey);
    }
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
}
