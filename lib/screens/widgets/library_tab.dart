import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/card.dart';
import '../../data/card_group.dart';
import '../../data/card_set.dart';
import '../../data/library_filters.dart';
import '../../state/library_state.dart';
import 'card_detail_view.dart';

/// One scrollable list of cards with a search bar.
///
/// Cards are grouped by name. Multiple pitch variants of the same card render
/// as one row with a multi-color indicator.
///
/// Search matches:
///   - Card name (substring, case-insensitive).
///   - Functional text (substring, case-insensitive).
///   - Set ID (exact match, case-insensitive).
///   - Set name (exact match, case-insensitive).
class LibraryTab extends StatefulWidget {
  final List<CardData> cards;
  final LibraryFilters filters;
  final VoidCallback onEditFilters;

  const LibraryTab({
    super.key,
    required this.cards,
    required this.filters,
    required this.onEditFilters,
  });

  @override
  State<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends State<LibraryTab> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String _appliedQuery = '';
  late List<CardGroup> _sortedGroups;

  @override
  void initState() {
    super.initState();
    _sortedGroups = _alphabetize(CardGroup.from(widget.cards));
  }

  @override
  void didUpdateWidget(covariant LibraryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cards != widget.cards) {
      _sortedGroups = _alphabetize(CardGroup.from(widget.cards));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<CardGroup> _alphabetize(List<CardGroup> groups) {
    final sorted = List<CardGroup>.from(groups);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }

  void _onSearchChanged(String raw) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        _appliedQuery = raw.trim();
      });
    });
  }

  /// Tier classification for a matched group. Lower number = higher rank.
  ///
  /// 0: name equals query exactly
  /// 1: name starts with query
  /// 2: name contains query
  /// 3: any variant's functional text contains query
  /// 4: any variant's printing belongs to a matching set
  /// null: no match
  int? _matchTier(CardGroup group, String q, Set<String> exactSetIds) {
    final name = group.name.toLowerCase();
    if (name == q) return 0;
    if (name.startsWith(q)) return 1;
    if (name.contains(q)) return 2;

    for (final v in group.variants) {
      if (v.functionalTextPlain.toLowerCase().contains(q)) return 3;
    }

    if (exactSetIds.isNotEmpty) {
      for (final v in group.variants) {
        for (final p in v.printings) {
          if (exactSetIds.contains(p.setId)) return 4;
        }
      }
    }

    return null;
  }

  /// Apply LibraryFilters: filter cards, regroup, sort alphabetically.
  /// Only computed when filters change (callers should call this once).
  List<CardGroup> _applyFilters(LibraryFilters filters) {
    if (filters.isEmpty) return _sortedGroups;
    final filteredCards = widget.cards.where(filters.passes).toList();
    return _alphabetize(CardGroup.from(filteredCards));
  }

  List<CardGroup> _filtered(List<CardSet> sets) {
    final base = _applyFilters(widget.filters);

    if (_appliedQuery.isEmpty) return base;

    final q = _appliedQuery.toLowerCase();
    final exactSetIds = <String>{};
    for (final s in sets) {
      if (s.id.toLowerCase() == q) exactSetIds.add(s.id);
      if (s.name.toLowerCase() == q) exactSetIds.add(s.id);
    }

    final scored = <(int, CardGroup)>[];
    for (final group in base) {
      final tier = _matchTier(group, q, exactSetIds);
      if (tier != null) scored.add((tier, group));
    }
    scored.sort((a, b) {
      if (a.$1 != b.$1) return a.$1.compareTo(b.$1);
      return a.$2.name.toLowerCase().compareTo(b.$2.name.toLowerCase());
    });
    return scored.map((s) => s.$2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryState>();
    final filtered = _filtered(library.sets);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by name, text, or set',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.filter_list, size: 18),
              label: Text(
                widget.filters.activeCount == 0
                    ? 'Filter'
                    : 'Filter (${widget.filters.activeCount})',
              ),
              onPressed: widget.onEditFilters,
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No cards found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final group = filtered[index];
                    return _CardListRow(
                      group: group,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CardDetailView(card: group.representative),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// One row representing a card group.
class _CardListRow extends StatelessWidget {
  final CardGroup group;
  final VoidCallback onTap;

  const _CardListRow({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _GroupIndicator(group: group),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                group.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// 18x18 indicator showing the role of a card group: hero/token/equipment
/// letter badge, single pitch dot, two-dot row, or three-dot triangle.
class _GroupIndicator extends StatelessWidget {
  final CardGroup group;
  const _GroupIndicator({required this.group});

  static const double _box = 18.0;

  @override
  Widget build(BuildContext context) {
    final rep = group.representative;
    final types = rep.types;

    if (types.contains('Hero')) {
      return const _LetterBadge(letter: 'H', color: Color(0xFF6A4E9C));
    }
    if (types.contains('Token')) {
      return const _LetterBadge(letter: 'T', color: Color(0xFF6B7280));
    }
    if (types.contains('Equipment')) {
      return const _LetterBadge(letter: 'E', color: Color(0xFF8C6E3F));
    }

    final pitches = group.pitchValues;
    if (pitches.isEmpty) {
      return _SizedDot(color: Colors.grey, diameter: _box);
    }
    if (pitches.length == 1) {
      return _SizedDot(color: _pitchColor(pitches.first), diameter: _box);
    }
    if (pitches.length == 2) {
      return _TwoDotRow(colors: pitches.map(_pitchColor).toList());
    }
    return _ThreeDotTriangle(colors: pitches.map(_pitchColor).toList());
  }

  static Color _pitchColor(int pitch) {
    switch (pitch) {
      case 1:
        return const Color(0xFFC0392B);
      case 2:
        return const Color(0xFFF1C40F);
      case 3:
        return const Color(0xFF2980B9);
      default:
        return Colors.grey;
    }
  }
}

class _LetterBadge extends StatelessWidget {
  final String letter;
  final Color color;
  const _LetterBadge({required this.letter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }
}

class _SizedDot extends StatelessWidget {
  final Color color;
  final double diameter;
  const _SizedDot({required this.color, required this.diameter});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Two dots side-by-side within an 18x18 box.
class _TwoDotRow extends StatelessWidget {
  final List<Color> colors;
  const _TwoDotRow({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SizedDot(color: colors[0], diameter: 8),
          const SizedBox(width: 2),
          _SizedDot(color: colors[1], diameter: 8),
        ],
      ),
    );
  }
}

/// Three dots in a triangle within an 18x18 box: top center, bottom left,
/// bottom right. Colors arrive sorted by pitch (1=red, 2=yellow, 3=blue).
class _ThreeDotTriangle extends StatelessWidget {
  final List<Color> colors;
  const _ThreeDotTriangle({required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        children: [
          // Red top-center
          Positioned(
            top: 0,
            left: 5,
            child: _SizedDot(color: colors[0], diameter: 8),
          ),
          // Yellow bottom-left
          Positioned(
            bottom: 0,
            left: 0,
            child: _SizedDot(color: colors[1], diameter: 8),
          ),
          // Blue bottom-right
          Positioned(
            bottom: 0,
            right: 0,
            child: _SizedDot(color: colors[2], diameter: 8),
          ),
        ],
      ),
    );
  }
}