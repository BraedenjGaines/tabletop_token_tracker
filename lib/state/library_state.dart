import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../data/card.dart';
import '../data/card_set.dart';

/// Owns the loaded card and set data. Loaded once at app startup.
///
/// While loading, [isLoaded] is false. Consumers should show a loading state
/// rather than reading the lists.
class LibraryState extends ChangeNotifier {
  bool _isLoaded = false;
  bool _loadFailed = false;
  String? _loadError;

  List<CardData> _cards = const [];
  List<CardSet> _sets = const [];

  bool get isLoaded => _isLoaded;
  bool get loadFailed => _loadFailed;
  String? get loadError => _loadError;

  /// All cards. Empty until [isLoaded] is true.
  List<CardData> get cards => _cards;

  /// All sets. Empty until [isLoaded] is true.
  List<CardSet> get sets => _sets;

  /// Heroes only — convenience filter.
  Iterable<CardData> get heroes => _cards.where((c) => c.isHero);

  /// Non-hero cards — convenience filter.
  Iterable<CardData> get otherCards => _cards.where((c) => !c.isHero);

  Future<void> loadFromAssets() async {
    try {
      final cardsJson = await rootBundle.loadString('assets/data/cards.json');
      final setsJson = await rootBundle.loadString('assets/data/sets.json');

      final cardsRaw = jsonDecode(cardsJson) as List<dynamic>;
      final setsRaw = jsonDecode(setsJson) as List<dynamic>;

      _cards = cardsRaw
          .map((e) => CardData.fromJson(e as Map<String, dynamic>))
          .toList();
      _sets = setsRaw
          .map((e) => CardSet.fromJson(e as Map<String, dynamic>))
          .toList();

      _isLoaded = true;
      _loadFailed = false;
      _loadError = null;

      debugPrint('LibraryState loaded ${_cards.length} cards, ${_sets.length} sets');
    } catch (e, stack) {
      _loadFailed = true;
      _loadError = e.toString();
      debugPrint('LibraryState load failed: $e\n$stack');
    }
    notifyListeners();
  }
}