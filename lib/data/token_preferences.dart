import 'package:shared_preferences/shared_preferences.dart';

class TokenPreferences {
  static Future<List<String>> getCustomTokens(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('customTokens_$gameId') ?? [];
  }

  static Future<void> addCustomToken(String gameId, String tokenName) async {
    final prefs = await SharedPreferences.getInstance();
    final tokens = prefs.getStringList('customTokens_$gameId') ?? [];
    if (!tokens.contains(tokenName)) {
      tokens.add(tokenName);
      await prefs.setStringList('customTokens_$gameId', tokens);
    }
  }

  static Future<void> removeCustomToken(String gameId, String tokenName) async {
    final prefs = await SharedPreferences.getInstance();
    final tokens = prefs.getStringList('customTokens_$gameId') ?? [];
    tokens.remove(tokenName);
    await prefs.setStringList('customTokens_$gameId', tokens);
  }

  static Future<List<String>> getFavorites(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('favoriteTokens_$gameId') ?? [];
  }

  static Future<void> toggleFavorite(String gameId, String tokenName) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList('favoriteTokens_$gameId') ?? [];
    if (favorites.contains(tokenName)) {
      favorites.remove(tokenName);
    } else {
      favorites.add(tokenName);
    }
    await prefs.setStringList('favoriteTokens_$gameId', favorites);
  }
}