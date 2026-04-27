import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameSettingsProvider extends ChangeNotifier {
  String selectedFont = 'Cinzel';
  String selectedGame = 'fab';
  bool turnTrackerEnabled = true;
  bool frostedGlass = false;
  int matchTimerMinutes = 50;
  int startingLife = 20;
  int resourceTrackerSetting = 3; // 0=Both, 1=AP Only, 2=Pitch Only, 3=None
  bool armorTrackingEnabled = false;
  String player1Name = 'Player 1';
  String player2Name = 'Player 2';
  String? player1HeroId;
  String? player2HeroId;
  bool clockEnabled = true;
  bool addTokenButtonEnabled = true;
  int damageDisplayMode = 0; // 0=Floating, 1=Totals
  bool isLoaded = false;

  late SharedPreferences _prefs;

  Future<void> loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    selectedFont = _prefs.getString('selectedFont') ?? 'Cinzel';
    selectedGame = _prefs.getString('selectedGame') ?? 'fab';
    turnTrackerEnabled = _prefs.getBool('turnTrackerEnabled') ?? true;
    frostedGlass = _prefs.getBool('frostedGlass') ?? false;
    matchTimerMinutes = _prefs.getInt('matchTimerMinutes') ?? 50;
    startingLife = _prefs.getInt('startingLife') ?? 20;
    resourceTrackerSetting = _prefs.getInt('resourceTrackerSetting') ?? 3;
    armorTrackingEnabled = _prefs.getBool('armorTrackingEnabled') ?? false;
    clockEnabled = _prefs.getBool('clockEnabled') ?? true;
    addTokenButtonEnabled = _prefs.getBool('addTokenButtonEnabled') ?? true;
    damageDisplayMode = _prefs.getInt('damageDisplayMode') ?? 0;
    isLoaded = true;
    notifyListeners();
  }

  void updateFont(String newFont) {
    selectedFont = newFont;
    _prefs.setString('selectedFont', newFont);
    notifyListeners();
  }

  void updateTurnTracker(bool enabled) {
    turnTrackerEnabled = enabled;
    _prefs.setBool('turnTrackerEnabled', enabled);
    notifyListeners();
  }

  void updateFrostedGlass(bool enabled) {
    frostedGlass = enabled;
    _prefs.setBool('frostedGlass', enabled);
    notifyListeners();
  }

  void updateMatchTimer(int minutes) {
    matchTimerMinutes = minutes;
    _prefs.setInt('matchTimerMinutes', minutes);
    notifyListeners();
  }

  void updateStartingLife(int value) {
    startingLife = value;
    _prefs.setInt('startingLife', value);
    notifyListeners();
  }

  void updateResourceTracker(int value) {
    resourceTrackerSetting = value;
    _prefs.setInt('resourceTrackerSetting', value);
    notifyListeners();
  }

  void updateArmorTracking(bool enabled) {
    armorTrackingEnabled = enabled;
    _prefs.setBool('armorTrackingEnabled', enabled);
    notifyListeners();
  }

  void updateClockEnabled(bool enabled) {
    clockEnabled = enabled;
    _prefs.setBool('clockEnabled', enabled);
    notifyListeners();
  }

  void updateAddTokenButtonEnabled(bool enabled) {
    addTokenButtonEnabled = enabled;
    _prefs.setBool('addTokenButtonEnabled', enabled);
    notifyListeners();
  }

  void updateDamageDisplayMode(int value) {
    damageDisplayMode = value;
    _prefs.setInt('damageDisplayMode', value);
    notifyListeners();
  }
}
