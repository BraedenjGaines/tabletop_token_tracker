import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/card.dart';
import '../../data/card_group.dart';

/// Full-screen view of a card group. Horizontal swipe between pitch variants;
/// foiling tabs at top to switch printing variant. Swipe-back gesture
/// disabled to prevent accidental dismiss while swiping between pitches.
class CardDetailView extends StatefulWidget {
  final CardGroup group;

  const CardDetailView({super.key, required this.group});

  @override
  State<CardDetailView> createState() => _CardDetailViewState();
}

class _CardDetailViewState extends State<CardDetailView> {
  late final PageController _pageController;
  int _pitchIndex = 0;

  /// Currently selected foiling code per pitch index. Cached so that switching
  /// back to a previously-viewed pitch restores the user's last foiling
  /// choice.
  final Map<int, String> _selectedFoilingByPitch = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// All variants in the group, sorted by pitch. Same ordering as
  /// CardGroup.variants (already pitch-ascending from CardGroup.from).
  List<CardData> get _variants => widget.group.variants;

  CardData get _currentVariant => _variants[_pitchIndex];

  /// Available foiling codes for the current pitch variant, in a sensible
  /// display order: Standard first, then Rainbow Foil, Cold Foil, Gold,
  /// then anything else alphabetically.
  List<String> get _availableFoilings {
    final foilings = _currentVariant.printings
        .where((p) => p.imageUrl.isNotEmpty)
        .map((p) => p.foiling)
        .toSet()
        .toList();
    const order = ['S', 'R', 'C', 'G'];
    foilings.sort((a, b) {
      final ai = order.indexOf(a);
      final bi = order.indexOf(b);
      if (ai != -1 && bi != -1) return ai.compareTo(bi);
      if (ai != -1) return -1;
      if (bi != -1) return 1;
      return a.compareTo(b);
    });
    return foilings;
  }

  /// Selected foiling for the current pitch. Falls back to first available.
  String get _selectedFoiling {
    final available = _availableFoilings;
    if (available.isEmpty) return '';
    final cached = _selectedFoilingByPitch[_pitchIndex];
    if (cached != null && available.contains(cached)) return cached;
    return available.first;
  }

  void _onPitchChanged(int index) {
    setState(() {
      _pitchIndex = index;
    });
  }

  void _onFoilingTapped(String foiling) {
    setState(() {
      _selectedFoilingByPitch[_pitchIndex] = foiling;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Disable iOS swipe-back. Forces explicit AppBar close.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // Only allow pop via the AppBar leading button (which we wire
        // explicitly below).
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(widget.group.name),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_availableFoilings.length > 1) _buildFoilingTabs(),
              Expanded(child: _buildPitchPager()),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoilingTabs() {
    final foilings = _availableFoilings;
    final selected = _selectedFoiling;
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: foilings.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = foilings[index];
          final isSelected = f == selected;
          return ChoiceChip(
            label: Text(_foilingLabel(f)),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => _onFoilingTapped(f),
            backgroundColor: Colors.grey[800],
            selectedColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey[600]!, width: 0.5),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPitchPager() {
    return PageView.builder(
      controller: _pageController,
      physics: const ClampingScrollPhysics(),
      itemCount: _variants.length,
      onPageChanged: _onPitchChanged,
      itemBuilder: (context, index) {
        // Render image for this pitch + currently-selected foiling.
        // Each page rebuilds against current state (foiling chosen at top).
        return Center(
          child: _buildImageForPitch(index),
        );
      },
    );
  }

  Widget _buildImageForPitch(int pitchIndex) {
    final variant = _variants[pitchIndex];
    final foiling = pitchIndex == _pitchIndex
        ? _selectedFoiling
        : _foilingForPitch(pitchIndex);

    // Find a printing that matches; if not, fall back to first with image.
    CardPrinting? printing;
    final exact = variant.printings.where(
      (p) => p.foiling == foiling && p.imageUrl.isNotEmpty,
    );
    if (exact.isNotEmpty) {
      printing = exact.first;
    } else {
      final any = variant.printings.where((p) => p.imageUrl.isNotEmpty);
      if (any.isNotEmpty) printing = any.first;
    }

    if (printing == null) {
      return const Text(
        'No printing available',
        style: TextStyle(color: Colors.white70),
      );
    }
    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: _CardImage(printing: printing),
    );
  }

  /// Foiling to use for a non-current pitch when rendering the pager.
  /// Same fall-back logic as the current pitch's foiling, but using only the
  /// cache (no current-pitch state).
  String _foilingForPitch(int pitchIndex) {
    final variant = _variants[pitchIndex];
    final available = variant.printings
        .where((p) => p.imageUrl.isNotEmpty)
        .map((p) => p.foiling)
        .toSet();
    if (available.isEmpty) return '';
    final cached = _selectedFoilingByPitch[pitchIndex];
    if (cached != null && available.contains(cached)) return cached;
    if (available.contains('S')) return 'S';
    return available.first;
  }

  Widget _buildPitchDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < _variants.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _PitchDot(
              color: _dotColor(_variants[i]),
              active: i == _pitchIndex,
            ),
          ),
      ],
    );
  }

  /// Bottom bar: info button on the left, pitch dots centered, empty space
  /// on the right to keep the row symmetric.
  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12, left: 8, right: 8),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            child: IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.white),
              tooltip: 'Card text',
              onPressed: () => _showCardInfo(context),
            ),
          ),
          Expanded(
            child: _variants.length > 1
                ? _buildPitchDots()
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Color _dotColor(CardData variant) {
    final pitch = int.tryParse(variant.pitch);
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

  String _foilingLabel(String code) {
    switch (code) {
      case 'S':
        return 'Standard';
      case 'R':
        return 'Rainbow Foil';
      case 'C':
        return 'Cold Foil';
      case 'G':
        return 'Gold';
      default:
        return code;
    }
  }

  /// Show a modal with the card's official text. Information shown:
  /// name + title, type line, stats (cost/pitch/power/defense as applicable),
  /// and the rules text. Works offline since this data is bundled.
  void _showCardInfo(BuildContext context) {
    final variant = _currentVariant;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatTitleLine(variant),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              if (variant.typeText.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  variant.typeText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white60,
                  ),
                ),
              ],
              if (_formatStatsLine(variant).isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _formatStatsLine(variant),
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    variant.functionalTextPlain.isEmpty
                        ? 'No card text.'
                        : variant.functionalTextPlain,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTitleLine(CardData v) {
    return v.name;
  }

  String _formatStatsLine(CardData v) {
    final parts = <String>[];
    if (v.cost.isNotEmpty) parts.add('Cost: ${v.cost}');
    if (v.pitch.isNotEmpty) parts.add('Pitch: ${v.pitch}');
    if (v.power.isNotEmpty) parts.add('Power: ${v.power}');
    if (v.defense.isNotEmpty) parts.add('Defense: ${v.defense}');
    return parts.join(' · ');
  }
}

class _PitchDot extends StatelessWidget {
  final Color color;
  final bool active;

  const _PitchDot({required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: active ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final CardPrinting printing;
  const _CardImage({required this.printing});

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: printing.imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, _) => const SizedBox(
        width: 80,
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      errorWidget: (_, _, _) => const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image, size: 64, color: Colors.white54),
            SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              'You may be offline.',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    if (printing.imageRotationDegrees != 0) {
      return Transform.rotate(
        angle: printing.imageRotationDegrees * 3.14159265 / 180,
        child: image,
      );
    }
    return image;
  }
}