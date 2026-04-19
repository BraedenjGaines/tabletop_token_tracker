/// Represents the state of a single armor equipment slot.
///
/// [isDestroyed] — whether the piece has been destroyed (long-press).
/// [counters]    — net modifier: negative = damage counters, positive = buff counters, 0 = fresh.
class ArmorSlotState {
  bool isDestroyed;
  int counters;

  ArmorSlotState({this.isDestroyed = false, this.counters = 0});

  void increment() {
    if (isDestroyed) {
      // Restore from destroyed
      isDestroyed = false;
      counters = 0;
    } else {
      counters++;
    }
  }

  void decrement() {
    if (isDestroyed) {
      // Restore from destroyed
      isDestroyed = false;
      counters = 0;
    } else {
      counters--;
    }
  }

  void destroy() {
    isDestroyed = true;
    counters = 0;
  }

  void reset() {
    isDestroyed = false;
    counters = 0;
  }

  bool get isDamaged => !isDestroyed && counters < 0;
  bool get isBuffed => !isDestroyed && counters > 0;
  double get displayOpacity => isDestroyed ? 0.2 : 1.0;
}
