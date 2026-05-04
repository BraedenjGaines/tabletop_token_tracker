import 'package:flutter/material.dart';
import '../../data/card.dart';
import '../../data/card_set.dart';
import '../../data/fab_constants.dart';
import '../../data/library_filters.dart';
import '../../data/main_sets.dart';

/// Modal bottom sheet for editing library filters. Returns the new
/// [LibraryFilters] when the user taps Apply, or `null` if dismissed.
class LibraryFilterSheet extends StatefulWidget {
  final LibraryFilters initial;
  final List<CardData> allCards;
  final List<CardSet> allSets;

  const LibraryFilterSheet({
    super.key,
    required this.initial,
    required this.allCards,
    required this.allSets,
  });

  static Future<LibraryFilters?> open({
    required BuildContext context,
    required LibraryFilters initial,
    required List<CardData> allCards,
    required List<CardSet> allSets,
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
      ),
    );
  }

  @override
  State<LibraryFilterSheet> createState() => _LibraryFilterSheetState();
}

enum _SectionId { type, subType, classFacet, talent, set, format }

class _LibraryFilterSheetState extends State<LibraryFilterSheet> {
  late LibraryFilters _draft;
  late TextEditingController _textController;

  late List<CardSet> _setsByRecency;

  _SectionId? _expanded;

  String _typeSearch = '';
  String _subTypeSearch = '';
  String _classSearch = '';
  String _talentSearch = '';
  String _setSearch = '';

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _textController = TextEditingController(text: _draft.containsText);
    _setsByRecency = _sortSetsByRecency(widget.allSets);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Filter to main sets only. Preserves alphabetical order since the
  /// upstream set.json doesn't provide release_date.
  List<CardSet> _sortSetsByRecency(List<CardSet> sets) {
    final mainOnly = sets.where((s) => kMainSetIds.contains(s.id)).toList();
    mainOnly.sort((a, b) => a.name.compareTo(b.name));
    return mainOnly;
  }

  void _toggleSection(_SectionId id) {
    setState(() {
      if (_expanded == id) {
        _expanded = null;
      } else {
        _expanded = id;
        _typeSearch = '';
        _subTypeSearch = '';
        _classSearch = '';
        _talentSearch = '';
        _setSearch = '';
      }
    });
    FocusScope.of(context).unfocus();
  }

  void _toggleType(String t) {
    setState(() {
      final next = Set<String>.from(_draft.types);
      next.contains(t) ? next.remove(t) : next.add(t);
      _draft = _draft.copyWith(types: next);
    });
  }

  void _toggleSubType(String s) {
    setState(() {
      final next = Set<String>.from(_draft.subTypes);
      next.contains(s) ? next.remove(s) : next.add(s);
      _draft = _draft.copyWith(subTypes: next);
    });
  }

  void _toggleClass(String c) {
    setState(() {
      final next = Set<String>.from(_draft.classes);
      next.contains(c) ? next.remove(c) : next.add(c);
      _draft = _draft.copyWith(classes: next);
    });
  }

  void _toggleTalent(String t) {
    setState(() {
      final next = Set<String>.from(_draft.talents);
      next.contains(t) ? next.remove(t) : next.add(t);
      _draft = _draft.copyWith(talents: next);
    });
  }

  void _toggleFormat(FormatChoice f) {
    setState(() {
      final next = Set<FormatChoice>.from(_draft.formats);
      next.contains(f) ? next.remove(f) : next.add(f);
      _draft = _draft.copyWith(formats: next);
    });
  }

  void _toggleSet(String setId) {
    setState(() {
      final next = Set<String>.from(_draft.setIds);
      next.contains(setId) ? next.remove(setId) : next.add(setId);
      _draft = _draft.copyWith(setIds: next);
    });
  }

  void _reset() {
    setState(() {
      _draft = const LibraryFilters();
      _textController.clear();
      _typeSearch = '';
      _subTypeSearch = '';
      _classSearch = '';
      _talentSearch = '';
      _setSearch = '';
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
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTypeSection(),
                  const SizedBox(height: 12),
                  _buildSubTypeSection(),
                  const SizedBox(height: 12),
                  _buildClassSection(),
                  const SizedBox(height: 12),
                  _buildTalentSection(),
                  const SizedBox(height: 12),
                  _buildSetSection(),
                  const SizedBox(height: 12),
                  _buildFormatSection(),
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

  Widget _buildTypeSection() {
    final query = _typeSearch.toLowerCase();
    final options = kFabTypes
        .where((t) => query.isEmpty || t.toLowerCase().contains(query))
        .toList();

    return _CollapsibleMultiSelect(
      title: 'Type',
      summary: _summarize(_draft.types.toList()..sort()),
      expanded: _expanded == _SectionId.type,
      onToggle: () => _toggleSection(_SectionId.type),
      onSearchChanged: (q) => setState(() => _typeSearch = q),
      child: Column(
        children: [
          for (final t in options)
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

  Widget _buildSubTypeSection() {
    final query = _subTypeSearch.toLowerCase();
    final options = kFabSubTypes
        .where((s) => query.isEmpty || s.toLowerCase().contains(query))
        .toList();

    return _CollapsibleMultiSelect(
      title: 'Sub-Type',
      summary: _summarize(_draft.subTypes.toList()..sort()),
      expanded: _expanded == _SectionId.subType,
      onToggle: () => _toggleSection(_SectionId.subType),
      onSearchChanged: (q) => setState(() => _subTypeSearch = q),
      child: Column(
        children: [
          for (final s in options)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _draft.subTypes.contains(s),
              onChanged: (_) => _toggleSubType(s),
              title: Text(s),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
    );
  }

  Widget _buildClassSection() {
    final query = _classSearch.toLowerCase();
    final options = kFabClasses
        .where((c) => query.isEmpty || c.toLowerCase().contains(query))
        .toList();

    return _CollapsibleMultiSelect(
      title: 'Class',
      summary: _summarize(_draft.classes.toList()..sort()),
      expanded: _expanded == _SectionId.classFacet,
      onToggle: () => _toggleSection(_SectionId.classFacet),
      onSearchChanged: (q) => setState(() => _classSearch = q),
      child: Column(
        children: [
          for (final c in options)
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

  Widget _buildTalentSection() {
    final query = _talentSearch.toLowerCase();
    final options = kFabTalents
        .where((t) => query.isEmpty || t.toLowerCase().contains(query))
        .toList();

    return _CollapsibleMultiSelect(
      title: 'Talent',
      summary: _summarize(_draft.talents.toList()..sort()),
      expanded: _expanded == _SectionId.talent,
      onToggle: () => _toggleSection(_SectionId.talent),
      onSearchChanged: (q) => setState(() => _talentSearch = q),
      child: Column(
        children: [
          for (final t in options)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: _draft.talents.contains(t),
              onChanged: (_) => _toggleTalent(t),
              title: Text(t),
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ),
    );
  }

  Widget _buildSetSection() {
    final query = _setSearch.toLowerCase();
    final options = _setsByRecency
        .where((s) =>
            query.isEmpty ||
            s.name.toLowerCase().contains(query) ||
            s.id.toLowerCase().contains(query))
        .toList();

    return _CollapsibleMultiSelect(
      title: 'Set',
      summary: _summarize(_draft.setIds.toList()..sort()),
      expanded: _expanded == _SectionId.set,
      onToggle: () => _toggleSection(_SectionId.set),
      onSearchChanged: (q) => setState(() => _setSearch = q),
      child: Column(
        children: [
          for (final set in options)
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

  Widget _buildFormatSection() {
    // Format has no per-section search. Still uses _CollapsibleMultiSelect
    // for consistent visual style.
    return _CollapsibleMultiSelect(
      title: 'Format',
      summary: _summarize(_draft.formats.map((f) => f.label).toList()..sort()),
      expanded: _expanded == _SectionId.format,
      onToggle: () => _toggleSection(_SectionId.format),
      onSearchChanged: (_) {},
      searchEnabled: false,
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

  String? _summarize(List<String> items) {
    if (items.isEmpty) return null;
    if (items.length <= 3) return items.join(', ');
    return '${items.take(2).join(', ')}, +${items.length - 2} more';
  }
}

class _CollapsibleMultiSelect extends StatefulWidget {
  final String title;
  final String? summary;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onSearchChanged;
  final Widget child;
  final bool searchEnabled;

  const _CollapsibleMultiSelect({
    required this.title,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    required this.onSearchChanged,
    required this.child,
    this.searchEnabled = true,
  });

  @override
  State<_CollapsibleMultiSelect> createState() =>
      _CollapsibleMultiSelectState();
}

class _CollapsibleMultiSelectState extends State<_CollapsibleMultiSelect> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(covariant _CollapsibleMultiSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expanded && !oldWidget.expanded) {
      _controller.clear();
      if (widget.searchEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      }
    }
    if (!widget.expanded && oldWidget.expanded) {
      _controller.clear();
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildHeader(),
          ),
        ),
        if (widget.expanded)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: widget.child,
          ),
      ],
    );
  }

  Widget _buildHeader() {
    final showInput = widget.expanded && widget.searchEnabled;
    return Row(
      children: [
        Icon(widget.expanded ? Icons.expand_less : Icons.expand_more),
        const SizedBox(width: 8),
        // Title stays visible whether expanded or not.
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        // To the right of the title:
        // - When expanded with search: a transparent inline input field.
        // - When collapsed: the summary of selected items, if any.
        Expanded(
          child: showInput ? _buildInlineInput() : _buildInlineSummary(),
        ),
      ],
    );
  }

  Widget _buildInlineSummary() {
    if (widget.summary == null) return const SizedBox.shrink();
    return Text(
      widget.summary!,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildInlineInput() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: widget.onSearchChanged,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        // Typed text uses a distinct color so the user can see it as
        // different from the section title.
        color: Theme.of(context).colorScheme.primary,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        hintText: '',
        border: const UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[400]!, width: 1),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
      ),
    );
  }
}