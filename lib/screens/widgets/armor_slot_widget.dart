import 'package:flutter/material.dart';
import '../../data/app_assets.dart';
import '../../data/armor_slot_state.dart';

class ArmorSlotWidget extends StatelessWidget {
  final ArmorSlotState state;
  final int slotIndex;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onDestroy;

  const ArmorSlotWidget({
    super.key,
    required this.state,
    required this.slotIndex,
    required this.onIncrement,
    required this.onDecrement,
    required this.onDestroy,
  });

  static const List<String> armorAssets = AppAssets.armorSlots;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 80,
      margin: EdgeInsets.all(3),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Opacity(
              opacity: state.displayOpacity,
              child: Image.asset(
                armorAssets[slotIndex],
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[800]),
              ),
            ),
          ),
          // Top half: + button
          Positioned(
            top: 0, left: 0, right: 0, height: 40,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onIncrement,
              child: Container(
                color: Colors.white.withValues(alpha: 0.1),
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text('+', style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.6), height: 0.65)),
                ),
              ),
            ),
          ),
          // Bottom half: - button
          Positioned(
            top: 40, left: 0, right: 0, height: 40,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDecrement,
              child: Container(
                color: Colors.white.withValues(alpha: 0.1),
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text('-', style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.6), height: 0.65)),
                ),
              ),
            ),
          ),
          // Counter badge - damaged
          if (state.isDamaged || state.isBuffed)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: state.isBuffed ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      state.isBuffed
                          ? '+${state.counters}'
                          : '${state.counters}',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // Long press to destroy
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: state.isDestroyed ? null : onDestroy,
            ),
          ),
        ],
      ),
    );
  }
}
