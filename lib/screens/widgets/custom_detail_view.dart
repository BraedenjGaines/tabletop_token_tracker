import 'package:flutter/material.dart';
import '../../data/hero_library.dart';
import '../../data/token_library.dart';
import 'custom_image.dart';

/// Full-screen detail view for a custom hero or custom token. Mirrors the
/// structure of [CardDetailView] but reads from the custom-data shape.
///
/// Exactly one of [hero] or [token] must be non-null. The widget renders
/// the user's custom image (or a default), an info button revealing the
/// stored fields, and edit/delete buttons that call back to the parent.
class CustomDetailView extends StatelessWidget {
  final HeroData? hero;
  final TokenData? token;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CustomDetailView({
    super.key,
    this.hero,
    this.token,
    required this.onEdit,
    required this.onDelete,
  }) : assert(
          (hero != null) ^ (token != null),
          'Pass exactly one of hero or token',
        );

  String get _displayName {
    if (hero != null) return hero!.name;
    return token!.name;
  }

  String? get _customImagePath {
    if (hero != null) return hero!.customImagePath;
    return token!.customImagePath;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {},
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
          title: Text(_displayName),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: Center(child: _buildImage())),
              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return CustomImage(path: _customImagePath, fit: BoxFit.contain);
  }

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            tooltip: 'Info',
            onPressed: () => _showInfo(context),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hero != null ? 'Delete Hero' : 'Delete Token'),
        content: Text('Delete $_displayName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showInfo(BuildContext context) {
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _displayName,
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
              const SizedBox(height: 8),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: hero != null ? _buildHeroInfo() : _buildTokenInfo(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroInfo() {
    final h = hero!;
    final lines = <String>[];
    lines.add('Class: ${_classLabel(h.heroClass)}');
    final talentLabels = h.talents
        .where((t) => t != HeroTalent.none)
        .map(_talentLabel)
        .toList();
    if (talentLabels.isNotEmpty) {
      lines.add('Talents: ${talentLabels.join(', ')}');
    }
    if (h.intellect > 0) lines.add('Intellect: ${h.intellect}');
    if (h.health > 0) lines.add('Life: ${h.health}');
    return _buildInfoBlock(stats: lines.join('\n'), cardText: h.cardText);
  }

  Widget _buildTokenInfo() {
    final t = token!;
    final lines = <String>[];
    lines.add('Sub-Type: ${_categoryLabel(t.category)}');
    if (t.category == TokenCategory.aura && t.auraType != null) {
      lines.add('Aura Type: ${_auraTypeLabel(t.auraType!)}');
    }
    if (t.destroyTrigger != null) {
      lines.add('Destroys: ${_triggerLabel(t.destroyTrigger!)}');
    }
    if (t.health != null) lines.add('Life: ${t.health}');
    return _buildInfoBlock(stats: lines.join('\n'), cardText: t.cardText);
  }

  /// Combined info-modal body: stats line on top, optional card text below
  /// under a heading. Card-text section is suppressed when empty.
  Widget _buildInfoBlock({required String stats, required String cardText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stats,
          style: const TextStyle(fontSize: 14, color: Colors.white, height: 1.6),
        ),
        if (cardText.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text(
            'Card Text',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            cardText,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.5,
            ),
          ),
        ],
      ],
    );
  }

  String _classLabel(HeroClass c) {
    const map = {
      HeroClass.brute: 'Brute',
      HeroClass.guardian: 'Guardian',
      HeroClass.illusionist: 'Illusionist',
      HeroClass.mechanologist: 'Mechanologist',
      HeroClass.merchant: 'Merchant',
      HeroClass.ninja: 'Ninja',
      HeroClass.ranger: 'Ranger',
      HeroClass.runeblade: 'Runeblade',
      HeroClass.warrior: 'Warrior',
      HeroClass.wizard: 'Wizard',
      HeroClass.assassin: 'Assassin',
      HeroClass.bard: 'Bard',
      HeroClass.necromancer: 'Necromancer',
      HeroClass.shapeshifter: 'Shapeshifter',
      HeroClass.adjudicator: 'Adjudicator',
      HeroClass.generic: 'Generic',
    };
    return map[c] ?? c.name;
  }

  String _talentLabel(HeroTalent t) {
    const map = {
      HeroTalent.draconic: 'Draconic',
      HeroTalent.earth: 'Earth',
      HeroTalent.elemental: 'Elemental',
      HeroTalent.ice: 'Ice',
      HeroTalent.light: 'Light',
      HeroTalent.lightning: 'Lightning',
      HeroTalent.shadow: 'Shadow',
      HeroTalent.royal: 'Royal',
      HeroTalent.mystic: 'Mystic',
    };
    return map[t] ?? t.name;
  }

  String _categoryLabel(TokenCategory c) {
    const map = {
      TokenCategory.ally: 'Ally',
      TokenCategory.aura: 'Aura',
      TokenCategory.item: 'Item',
      TokenCategory.genericToken: 'Generic Token',
      TokenCategory.landmark: 'Landmark',
    };
    return map[c] ?? c.name;
  }

  String _auraTypeLabel(AuraType a) {
    const map = {
      AuraType.buff: 'Buff',
      AuraType.debuff: 'Debuff',
    };
    return map[a] ?? a.name;
  }

  String _triggerLabel(DestroyTrigger t) {
    const map = {
      DestroyTrigger.startOfYourTurn: 'Start of Your Turn',
      DestroyTrigger.startOfOpponentTurn: 'Start of Opponent Turn',
      DestroyTrigger.beginningOfActionPhase: 'Beginning of Action Phase',
      DestroyTrigger.beginningOfEndPhase: 'Beginning of End Phase',
    };
    return map[t] ?? t.name;
  }
}