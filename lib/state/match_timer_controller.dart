import 'dart:async';
import 'package:flutter/foundation.dart';

/// Owns match-timer state. Pure state — no rendering, no flash logic.
///
/// Display concerns like flashing on expiry belong to the widget that renders
/// the timer; this controller only exposes the underlying countdown and whether
/// it has expired.
class MatchTimerController extends ChangeNotifier {
  MatchTimerController({required int initialSeconds})
      : _initialSeconds = initialSeconds,
        _secondsRemaining = initialSeconds;

  final int _initialSeconds;

  int _secondsRemaining;
  Timer? _ticker;
  bool _isRunning = false;

  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  bool get isExpired => _secondsRemaining <= 0;

  void start() {
    if (_isRunning) return;
    if (_secondsRemaining <= 0) {
      reset();
      return;
    }
    _isRunning = true;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _ticker?.cancel();
        _isRunning = false;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void pause() {
    _ticker?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void reset() {
    _ticker?.cancel();
    _isRunning = false;
    _secondsRemaining = _initialSeconds;
    notifyListeners();
  }

  void toggle() {
    if (_isRunning) {
      pause();
    } else {
      start();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}