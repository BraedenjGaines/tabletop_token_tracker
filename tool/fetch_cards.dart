// Fetches card and set data from the-fab-cube/flesh-and-blood-cards at a
// pinned release version, strips fields the app doesn't use, and writes
// assets/data/cards.json and assets/data/sets.json.
//
// Usage:
//   dart run tool/fetch_cards.dart
//
// To update card data when a new set releases: bump _version below to the new
// release tag, re-run the script, ship a new app version.

// This is a build-time CLI script, not production app code. `print` is the
// expected output mechanism; the avoid_print rule doesn't apply here.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const String _version = 'v8.1.0';
const String _baseUrl =
    'https://raw.githubusercontent.com/the-fab-cube/flesh-and-blood-cards';

const String _cardsUrl = '$_baseUrl/$_version/json/english/card.json';
const String _setsUrl = '$_baseUrl/$_version/json/english/set.json';

const String _outDir = 'assets/data';
const String _cardsOut = '$_outDir/cards.json';
const String _setsOut = '$_outDir/sets.json';

Future<void> main() async {
  print('Fetching card data at $_version...');
  await Directory(_outDir).create(recursive: true);

  await _processCards();
  await _processSets();

  print('Done.');
}

Future<void> _processCards() async {
  print('  Downloading $_cardsUrl');
  final response = await http.get(Uri.parse(_cardsUrl));
  if (response.statusCode != 200) {
    throw Exception('Failed to download cards: ${response.statusCode}');
  }
  print('  Downloaded ${response.bodyBytes.length} bytes');

  final List<dynamic> raw = jsonDecode(utf8.decode(response.bodyBytes));
  print('  Parsing ${raw.length} cards');

  final stripped = raw.map(_stripCard).toList();
  final outBytes = utf8.encode(jsonEncode(stripped));
  await File(_cardsOut).writeAsBytes(outBytes);

  final sizeKb = (outBytes.length / 1024).toStringAsFixed(1);
  print('  Wrote $_cardsOut ($sizeKb KB, ${stripped.length} cards)');
}

Future<void> _processSets() async {
  print('  Downloading $_setsUrl');
  final response = await http.get(Uri.parse(_setsUrl));
  if (response.statusCode != 200) {
    throw Exception('Failed to download sets: ${response.statusCode}');
  }
  print('  Downloaded ${response.bodyBytes.length} bytes');

  final List<dynamic> raw = jsonDecode(utf8.decode(response.bodyBytes));
  final stripped = raw.map(_stripSet).toList();
  final outBytes = utf8.encode(jsonEncode(stripped));
  await File(_setsOut).writeAsBytes(outBytes);

  final sizeKb = (outBytes.length / 1024).toStringAsFixed(1);
  print('  Wrote $_setsOut ($sizeKb KB, ${stripped.length} sets)');
}

/// Trims fields the app doesn't use to keep bundle size small.
Map<String, dynamic> _stripCard(dynamic raw) {
  final card = raw as Map<String, dynamic>;
  return {
    'unique_id': card['unique_id'],
    'name': card['name'],
    'color': card['color'],
    'pitch': card['pitch'],
    'cost': card['cost'],
    'power': card['power'],
    'defense': card['defense'],
    'health': card['health'],
    'intelligence': card['intelligence'],
    'arcane': card['arcane'],
    'types': card['types'],
    'traits': card['traits'],
    'card_keywords': card['card_keywords'],
    'functional_text': card['functional_text'],
    'functional_text_plain': card['functional_text_plain'],
    'type_text': card['type_text'],
    'played_horizontally': card['played_horizontally'],
    // Format legality (kept for filter support).
    'blitz_legal': card['blitz_legal'],
    'cc_legal': card['cc_legal'],
    'commoner_legal': card['commoner_legal'],
    'll_legal': card['ll_legal'],
    'silver_age_legal': card['silver_age_legal'],
    'blitz_living_legend': card['blitz_living_legend'],
    'cc_living_legend': card['cc_living_legend'],
    'blitz_banned': card['blitz_banned'],
    'cc_banned': card['cc_banned'],
    'commoner_banned': card['commoner_banned'],
    'll_banned': card['ll_banned'],
    'silver_age_banned': card['silver_age_banned'],
    'blitz_suspended': card['blitz_suspended'],
    'cc_suspended': card['cc_suspended'],
    'commoner_suspended': card['commoner_suspended'],
    'll_restricted': card['ll_restricted'],
    'printings': (card['printings'] as List<dynamic>? ?? [])
        .map(_stripPrinting)
        .toList(),
  };
}

Map<String, dynamic> _stripPrinting(dynamic raw) {
  final p = raw as Map<String, dynamic>;
  return {
    'id': p['id'],
    'set_id': p['set_id'],
    'edition': p['edition'],
    'foiling': p['foiling'],
    'rarity': p['rarity'],
    'image_url': p['image_url'],
    'image_rotation_degrees': p['image_rotation_degrees'],
    if (p['art_variations'] != null) 'art_variations': p['art_variations'],
  };
}

Map<String, dynamic> _stripSet(dynamic raw) {
  final s = raw as Map<String, dynamic>;
  return {
    'id': s['id'],
    'name': s['name'],
    if (s['release_date'] != null) 'release_date': s['release_date'],
  };
}