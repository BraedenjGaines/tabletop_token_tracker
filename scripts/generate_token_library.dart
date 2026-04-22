import 'dart:io';
import 'dart:convert';

void main() async {
  final basePath = 'C:/Users/Braeden/Desktop/flesh-and-blood-cards/json/english';
  
  final cardFile = File('$basePath/card.json');
  if (!cardFile.existsSync()) {
    print('Card JSON not found at ${cardFile.path}');
    return;
  }

  final cardJson = jsonDecode(await cardFile.readAsString()) as List<dynamic>;

  // Filter for token cards
  final tokens = cardJson.where((card) {
    final types = card['types'] as List<dynamic>? ?? [];
    return types.any((t) => t.toString().toLowerCase() == 'token');
  }).toList();

  print('Found ${tokens.length} token cards');

  // Create output directory
  final tokenImagesDir = Directory('assets/images/tokens');
  if (!tokenImagesDir.existsSync()) {
    tokenImagesDir.createSync(recursive: true);
    print('Created ${tokenImagesDir.path}');
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

  // Determine token category from types
  String categorize(List<dynamic> types) {
    final typeStrs = types.map((t) => t.toString().toLowerCase()).toList();
    if (typeStrs.contains('ally')) return 'ally';
    if (typeStrs.contains('item')) return 'item';
    if (typeStrs.contains('aura')) {
      // Check for debuff keywords or known debuffs
      return 'aura';
    }
    return 'other';
  }

  int downloadCount = 0;
  int skipCount = 0;
  int failCount = 0;

  final buffer = StringBuffer();

  for (final token in tokens) {
    final name = token['name'] as String;
    final types = token['types'] as List<dynamic>? ?? [];
    final health = int.tryParse(token['health']?.toString() ?? '') ?? 0;
    final category = categorize(types);

    // Generate ID
    String id = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    // Escape single quotes
    final escapedName = name.replaceAll("'", "\\'");

    final typeList = types.map((t) => t.toString()).join(', ');

    buffer.writeln("  // Types: $typeList");
    buffer.writeln("  // Category: $category${health > 0 ? ', Health: $health' : ''}");
    buffer.writeln("  // ID: $id");
    buffer.writeln("  // Name: $escapedName");
    buffer.writeln('');

    // Download card image
    final printings = token['printings'] as List<dynamic>? ?? [];
    String? imageUrl;
    for (final printing in printings) {
      final img = printing['image_url'] as String?;
      if (img != null && img.isNotEmpty) {
        imageUrl = img;
        break;
      }
    }

    if (imageUrl != null) {
      String ext = 'png';
      if (imageUrl.contains('.jpg') || imageUrl.contains('.jpeg')) ext = 'jpg';

      final cardPath = 'assets/images/tokens/${id}_card.$ext';
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

  // Write token list for reference
  final outputFile = File('token_library_generated.txt');
  await outputFile.writeAsString('''
// AUTO-GENERATED token list from flesh-and-blood-cards JSON
// Generated on: ${DateTime.now().toIso8601String()}
//
// Review this file and update your token_library.dart accordingly.
// Token card scans are downloaded to assets/images/tokens/
// You can add icon images manually as assets/images/tokens/<id>.png
//
// Token entries:
${buffer.toString()}
''');

  print('');
  print('=== SUMMARY ===');
  print('Tokens found: ${tokens.length}');
  print('Card images downloaded: $downloadCount');
  print('Card images skipped (already exist): $skipCount');
  print('Card images failed/missing: $failCount');
  print('');
  print('Generated token_library_generated.txt for reference');
  print('Token card scans are in assets/images/tokens/<id>_card.png');
  print('');
  print('Add to pubspec.yaml under assets:');
  print('  - assets/images/tokens/');
}