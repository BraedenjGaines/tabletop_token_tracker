import 'package:flutter/material.dart';
import '../../data/card.dart';
import '../../data/card_set.dart';
import '../../data/library_filters.dart';
import '../../data/main_sets.dart';

/// Modal bottom sheet for editing library filters. Returns the new
/// [LibraryFilters] when the user taps Apply, or `null` if the user dismisses
/// without applying.
class LibraryFilterSheet extends StatefulWidget {
  final LibraryFilters initial;
  final List<CardData> allCards;
  final List<CardSet> allSets;
  final Set<String> classNames;

  const LibraryFilterSheet({
    super.key,
    required this.initial,
    required this.allCards,
    required this.allSets,
    required this.classNames,
  });

  static Future<LibraryFilters?> open({
    required BuildContext context,
    required LibraryFilters initial,
    required List<CardData> allCards,
    required List<CardSet> allSets,
    required Set<String> classNames,
  }) {
    return showModalBottomSheet<LibraryFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => LibraryFilterSheet(
        initial: initial,
        allCards: allCards,
        allSets: allSets,
        classNames: classNames,
      ),
    );
  }

  @override
  State<LibraryFilterSheet> createState() => _LibraryFilterSheetState();
}

class _LibraryFilterSheetState extends State<LibraryFilterSheet> {
  late LibraryFilters _draft;
  late TextEditingController _textController;

  late List<String> _availableClasses;
  late List<String> _availableTypes;
  late List<CardSet> _setsByRecency;

  // Expansion state for collapsible sections. Showing and Cards-containing-text
  // are not collapsible (single-select dropdown / always-visible text input).
  bool _formatExpanded = false;
  bool _classExpanded = false;
  bool _typeExpanded = false;
  bool _setExpanded = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _textController = TextEditingController(text: _draft.containsText);
    _computeAvailableFacets();
    _setsByRecency = _sortSetsByRecency(widget.allSets);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _computeAvailableFacets() {
    final classes = <String>{};
    final types = <String>{};
    for (final card in widget.allCards) {
      for (final t in card.types) {
        if (widget.classNames.contains(t)) {
          classes.add(t);
        } else if (t != 'Hero') {
          types.add(t);
        }
      }
    }
    _availableClasses = classes.toList()..sort();
    _availableTypes = types.toList()..sort();
  }

  List<CardSet> _sortSetsByRecency(List<CardSet> sets) {
    final mainOnly = sets.where((s) => kMainSetIds.contains(s.id)).toList();
    mainOnly.sort((a, b) {
      final ad = a.releaseDate ?? '';
      final bd = b.releaseDate ?? '';
      if (ad.isEmpty && bd.isEmpty) return a.name.compareTo(b.name);
      if (ad.isEmpty) return 1;
      if (bd.isEmpty) return -1;
      return bd.compareTo(ad);
    });
    return mainOnly;
  }

  void _onCategoryChanged(LibraryCategory? c) {
    if (c == null) return;
    setState(() => _draft = _draft.copyWith(category: c));
  }

  void _toggleFormat(FormatChoice f) {
    setState(() {
      final next = Set<FormatChoice>.from(_draft.formats);
      next.contains(f) ? next.remove(f) : next.add(f);
      _draft = _draft.copyWith(formats: next);
    });
  }

  void _toggleClass(String c) {
    setState(() {
      final next = Set<String>.from(_draft.classes);
      next.contains(c) ? next.remove(c) : next.add(c);
      _draft = _draft.copyWith(classes: next);
    });
  }

  void _toggleType(String t) {
    setState(() {
      final next = Set<String>.from(_draft.types);
      next.contains(t) ? next.remove(t) : next.add(t);
      _draft = _draft.copyWith(types: next);
    });
  }

  void _toggleSet(String setId) {
    setState(() {
      final next = Set<String>.from(_draft.setIds);
      next.contains(setId) ? next.remove(setId) : next.add(setId);
      _draft = _draft.copyWith(setIds: next);
    });
  }

  void _onTextChanged(String value) {
    _draft = _draft.copyWith(containsText: value.trim());
  }

  void _reset() {
    setState(() {
      _draft = const LibraryFilters();
      _textController.clear();
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      _draft.copyWith(containsText: _textController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShowingSection(),
                  const SizedBox(height: 12),
                  _buildFormatSection(),
                  const SizedBox(height: 12),
                  _buildClassSection(),
                  const SizedBox(height: 12),
                  _buildTypeSection(),
                  const SizedBox(height: 12),
                  _buildSetSection(),
                  const SizedBox(height: 12),
                  _buildContainsTextSection(),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Filter',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(onPressed: _reset, child: const Text('Reset')),
        ],
      ),
    );
  }

  Widget _buildShowingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'Showing',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        DropdownButton<LibraryCategory>(
          value: _draft.category,
          isExpanded: true,
          onChanged: _onCategoryChanged,
          items: LibraryCategory.values
              .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFormatSection() {
    final summary = _draft.formats.isEmpty
        ? null
        : _draft.formats.map((f) => f.label).toList().join(', ');
    return _CollapsibleMultiSelect(
      title: 'Format',
      summary: summary,
      expanded: _formatExpanded,
      onToggle: () => setState(() => _formatExpanded = !_formatExpanded),
      child: Column(
        children: [
          for (final f in FormatChoice.values)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _draft.formats.contains(f),
              onChanged: (_) => _toggleFormat(f),
              title: Text(f.label),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
    );
  }

  Widget _buildClassSection() {
    final summary = _draft.classes.isEmpty
        ? null
        : _summarize(_draft.classes.toList()..sort());
    return _CollapsibleMultiSelect(
      title: 'Class',
      summary: summary,
      expanded: _classExpanded,
      onToggle: () => setState(() => _classExpanded = !_classExpanded),
      child: Column(
        children: [
          for (final c in _availableClasses)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _draft.classes.contains(c),
              onChanged: (_) => _toggleClass(c),
              title: Text(c),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSection() {
    final summary = _draft.types.isEmpty
        ? null
        : _summarize(_draft.types.toList()..sort());
    return _CollapsibleMultiSelect(
      title: 'Type',
      summary: summary,
      expanded: _typeExpanded,
      onToggle: () => setState(() => _typeExpanded = !_typeExpanded),
      child: Column(
        children: [
          for (final t in _availableTypes)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _draft.types.contains(t),
              onChanged: (_) => _toggleType(t),
              title: Text(t),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
    );
  }

  Widget _buildSetSection() {
    final summary = _draft.setIds.isEmpty
        ? null
        : _summarize(_draft.setIds.toList()..sort());
    return _CollapsibleMultiSelect(
      title: 'Set',
      summary: summary,
      expanded: _setExpanded,
      onToggle: () => setState(() => _setExpanded = !_setExpanded),
      child: Column(
        children: [
          for (final set in _setsByRecency)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _draft.setIds.contains(set.id),
              onChanged: (_) => _toggleSet(set.id),
              title: Text('${set.name} (${set.id})'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
    );
  }

  Widget _buildContainsTextSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            'Cards containing text',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        TextField(
          controller: _textController,
          onChanged: _onTextChanged,
          decoration: const InputDecoration(
            hintText: 'e.g. "Runechant"',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(onPressed: _apply, child: const Text('Apply')),
      ),
    );
  }

  /// Compact summary for collapsed section header. Caps long lists.
  String _summarize(List<String> items) {
    if (items.isEmpty) return '';
    if (items.length <= 3) return items.join(', ');
    return '${items.take(2).join(', ')}, +${items.length - 2} more';
  }
}

/// Collapsible multi-select section. Header tap toggles expansion. When
/// collapsed, [summary] (if non-null) is shown next to the title. The [child]
/// is shown only when expanded.
class _CollapsibleMultiSelect extends StatelessWidget {
  final String title;
  final String? summary;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  const _CollapsibleMultiSelect({
    required this.title,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(expanded ? Icons.expand_less : Icons.expand_more),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (summary != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (expanded) Padding(padding: const EdgeInsets.only(left: 32), child: child),
      ],
    );
  }
}