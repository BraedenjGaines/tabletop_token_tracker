import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'token_library.dart';

class TokenPreferences {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<List<TokenData>> getCustomTokens(String gameId) async {
    final prefs = await _getPrefs();
    final jsonList = prefs.getStringList('customTokensFull_$gameId') ?? [];
    return jsonList.map((json) {
      final map = jsonDecode(json);
      return TokenData(
        name: map['name'],
        category: TokenCategory.values[map['category']],
        destroyTrigger: map['destroyTrigger'] != null
            ? DestroyTrigger.values[map['destroyTrigger']]
            : null,
        health: map['health'],
      );
    }).toList();
  }

  static Future<void> addCustomToken(String gameId, TokenData token) async {
    final prefs = await _getPrefs();
    final jsonList = prefs.getStringList('customTokensFull_$gameId') ?? [];
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
      }));
      await prefs.setStringList('customTokensFull_$gameId', jsonList);
    }
  }

  static Future<void> removeCustomToken(String gameId, String tokenName) async {
    final prefs = await _getPrefs();
    final jsonList = prefs.getStringList('customTokensFull_$gameId') ?? [];
    jsonList.removeWhere((json) {
      final map = jsonDecode(json);
      return map['name'] == tokenName;
    });
    await prefs.setStringList('customTokensFull_$gameId', jsonList);

    // Clean up legacy format if it exists
    final legacyKey = 'customTokens_$gameId';
    if (prefs.containsKey(legacyKey)) {
      await prefs.remove(legacyKey);
    }
  }

  static Future<List<String>> getFavorites(String gameId) async {
    final prefs = await _getPrefs();
    return prefs.getStringList('favoriteTokens_$gameId') ?? [];
  }

  static Future<void> toggleFavorite(String gameId, String tokenName) async {
    final prefs = await _getPrefs();
    final favorites = prefs.getStringList('favoriteTokens_$gameId') ?? [];
    if (favorites.contains(tokenName)) {
      favorites.remove(tokenName);
    } else {
      favorites.add(tokenName);
    }
    await prefs.setStringList('favoriteTokens_$gameId', favorites);
  }
}
