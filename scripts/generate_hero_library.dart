import 'dart:io';
import 'dart:convert';

void main() async {
  // UPDATE THIS PATH to where you cloned the fab-cube repo
  final basePath = 'C:/Users/Braeden/Desktop/flesh-and-blood-cards/json/english';
  
  final cardFile = File('$basePath/card.json');
  if (!cardFile.existsSync()) {
    print('Card JSON not found at ${cardFile.path}');
    print('Clone https://github.com/the-fab-cube/flesh-and-blood-cards first');
    print('Then update basePath in this script');
    return;
  }

  final cardJson = jsonDecode(await cardFile.readAsString()) as List<dynamic>;

  // Filter for hero cards only
  final heroes = cardJson.where((card) {
    final types = card['types'] as List<dynamic>? ?? [];
    return types.any((t) => t.toString().toLowerCase() == 'hero');
  }).toList();

  print('Found ${heroes.length} hero cards');

  // Create output directories
  final heroImagesDir = Directory('assets/images/heroes');
  if (!heroImagesDir.existsSync()) {
    heroImagesDir.createSync(recursive: true);
    print('Created ${heroImagesDir.path}');
  }

  // Map classes
  String mapClass(List<dynamic> types) {
    final classTypes = [
      'Brute', 'Guardian', 'Illusionist', 'Mechanologist', 'Merchant',
      'Ninja', 'Ranger', 'Runeblade', 'Warrior', 'Wizard', 'Assassin',
      'Bard', 'Necromancer', 'Shapeshifter', 'Adjudicator',
    ];
    for (final t in types) {
      for (final c in classTypes) {
        if (t.toString().toLowerCase() == c.toLowerCase()) {
          return c;
        }
      }
    }
    return 'Generic';
  }

  // Map talents
  List<String> mapTalents(List<dynamic> types) {
    final talentTypes = [
      'Draconic', 'Earth', 'Elemental', 'Ice', 'Light',
      'Lightning', 'Shadow', 'Royal', 'Mystic',
    ];
    final found = <String>[];
    for (final t in types) {
      for (final talent in talentTypes) {
        if (t.toString().toLowerCase() == talent.toLowerCase()) {
          found.add(talent);
        }
      }
    }
    return found.isEmpty ? ['None'] : found;
  }

  // Determine if young
  bool isYoung(Map<String, dynamic> card) {
    final types = card['types'] as List<dynamic>? ?? [];
    return types.any((t) => t.toString().toLowerCase() == 'young');
  }

  // Generate ID from name
  String generateId(Map<String, dynamic> card) {
    String name = card['name'] as String;
    String id = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');
    if (isYoung(card)) {
      id += '_young';
    }
    return id;
  }

  // Download an image from a URL
  Future<bool> downloadImage(String url, String outputPath) async {
    try {
      final file = File(outputPath);
      if (file.existsSync()) {
        print('  SKIP (exists): $outputPath');
        return true;
      }

      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>(
          <int>[],
          (prev, element) => prev..addAll(element),
        );
        await file.writeAsBytes(bytes);
        print('  OK: $outputPath');
        client.close();
        return true;
      } else {
        print('  FAIL (${response.statusCode}): $url');
        client.close();
        return false;
      }
    } catch (e) {
      print('  ERROR: $url - $e');
      return false;
    }
  }

  // Process each hero
  final buffer = StringBuffer();
  int downloadCount = 0;
  int skipCount = 0;
  int failCount = 0;

  for (final hero in heroes) {
    final name = hero['name'] as String;
    final types = hero['types'] as List<dynamic>? ?? [];
    final health = int.tryParse(hero['health']?.toString() ?? '') ?? 0;
    final intellect = int.tryParse(hero['intellect']?.toString() ?? '') ?? 0;
    final heroClass = mapClass(types);
    final talents = mapTalents(types);
    final young = isYoung(hero as Map<String, dynamic>);
    final id = generateId(hero);

    // Split name into name and title
    String displayName = name;
    String title = '';
    if (name.contains(',')) {
      final parts = name.split(',');
      displayName = parts[0].trim();
      title = parts.sublist(1).join(',').trim();
    }

    // Escape single quotes in names
    displayName = displayName.replaceAll("'", "\\'");
    title = title.replaceAll("'", "\\'");

    final talentStr = talents.map((t) {
      if (t == 'None') return 'HeroTalent.none';
      return 'HeroTalent.${t.substring(0, 1).toLowerCase()}${t.substring(1)}';
    }).join(', ');

    final classStr = 'HeroClass.${heroClass.substring(0, 1).toLowerCase()}${heroClass.substring(1)}';

    buffer.writeln("  HeroData(id: '$id', name: '$displayName'${title.isNotEmpty ? ", title: '$title'" : ''}, heroClass: $classStr, talents: [$talentStr], isYoung: $young, intellect: $intellect, health: $health),");

    // Download card image (the card scan)
    final printings = hero['printings'] as List<dynamic>? ?? [];
    String? imageUrl;
    for (final printing in printings) {
      final img = printing['image_url'] as String?;
      if (img != null && img.isNotEmpty) {
        imageUrl = img;
        break; // Use the first available printing image
      }
    }

    if (imageUrl != null) {
      // Determine extension from URL
      String ext = 'png';
      if (imageUrl.contains('.jpg') || imageUrl.contains('.jpeg')) ext = 'jpg';

      final cardPath = 'assets/images/heroes/${id}_card.$ext';
      final result = await downloadImage(imageUrl, cardPath);
      if (result) {
        final file = File(cardPath);
        if (file.existsSync() && file.lengthSync() > 0) {
          downloadCount++;
        } else {
          skipCount++;
        }
      } else {
        failCount++;
      }
    } else {
      print('  NO IMAGE: $name');
      failCount++;
    }
  }

  // Write the generated Dart file
  final outputFile = File('hero_library_generated.dart');
  await outputFile.writeAsString('''
// AUTO-GENERATED from flesh-and-blood-cards JSON
// Generated on: ${DateTime.now().toIso8601String()}
//
// Steps:
// 1. Review this file for accuracy
// 2. Copy the heroLibrary list into lib/data/hero_library.dart
// 3. Hero card scans are downloaded to assets/images/heroes/
// 4. You still need hero ART images (character illustrations) — 
//    name them to match: assets/images/heroes/<id>.jpg
// 5. Register assets/images/heroes/ in pubspec.yaml

import 'hero_library.dart';

final List<HeroData> heroLibrary = [
${buffer.toString()}];
''');

  print('');
  print('=== SUMMARY ===');
  print('Heroes found: ${heroes.length}');
  print('Card images downloaded: $downloadCount');
  print('Card images skipped (already exist): $skipCount');
  print('Card images failed/missing: $failCount');
  print('');
  print('Generated hero_library_generated.dart');
  print('');
  print('NEXT STEPS:');
  print('1. Review hero_library_generated.dart');
  print('2. Copy the entries into lib/data/hero_library.dart');
  print('3. Card scans are in assets/images/heroes/<id>_card.png');
  print('4. You still need hero ART images (the character illustrations)');
  print('   Name them: assets/images/heroes/<id>.jpg');
  print('   These are used as player panel backgrounds');
  print('5. Add this to pubspec.yaml under assets:');
  print('     - assets/images/heroes/');
}