import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_settings_provider.dart';
import 'custom_token_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GameSettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Settings'), centerTitle: true),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Turn Tracker ---
              SizedBox(height: 32),
              Center(child: Text('Turn Tracker', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              Text('Shows phase tracking between players (Flesh and Blood, 2 players only)', style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Enable Turn Tracker'),
                value: settings.turnTrackerEnabled,
                onChanged: (value) => settings.updateTurnTracker(value),
              ),

              // --- First Turn ---
              SizedBox(height: 32),
              Center(child: Text('First Turn', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              Text('Determines who goes first in 2-player games', style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16, horizontal: 10)),
                    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 14, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily)),
                  ),
                  segments: [
                    ButtonSegment(value: 0, label: Text('Player 1')),
                    ButtonSegment(value: 2, label: Icon(Icons.casino, size: 28)),
                    ButtonSegment(value: 1, label: Text('Player 2')),
                  ],
                  selected: {settings.firstTurnSetting},
                  onSelectionChanged: (selection) => settings.updateFirstTurnSetting(selection.first),
                ),
              ),

              // --- Visual ---
              SizedBox(height: 32),
              Center(child: Text('Visual', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              Text('Applies a frosted glass blur effect to the player panels on the counter screen', style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Frosted Glass Effect'),
                value: settings.frostedGlass,
                onChanged: (value) => settings.updateFrostedGlass(value),
              ),
              SizedBox(height: 16),
              Center(child: Text('Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16, horizontal: 10)),
                    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 14, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily)),
                  ),
                  segments: [
                    ButtonSegment(value: ThemeMode.system, label: Text('System')),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (selection) => settings.updateThemeMode(selection.first),
                ),
              ),

              // --- Resource Tracking ---
              SizedBox(height: 32),
              SizedBox(width: double.infinity, child: Text('Resource Tracking', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              SizedBox(height: 8),
              Text('Track action points and pitch resources during gameplay', style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16, horizontal: 10)),
                    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 14, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily)),
                  ),
                  segments: [
                    ButtonSegment(value: 0, label: Text('Both')),
                    ButtonSegment(value: 1, label: Text('AP')),
                    ButtonSegment(value: 2, label: Text('Pitch')),
                    ButtonSegment(value: 3, label: Text('None')),
                  ],
                  selected: {settings.resourceTrackerSetting},
                  onSelectionChanged: (selection) => settings.updateResourceTracker(selection.first),
                ),
              ),

              // --- Damage Display ---
              SizedBox(height: 32),
              SizedBox(width: double.infinity, child: Text('Damage Display', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              SizedBox(height: 8),
              Text('How life changes appear on the counter screen', style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16, horizontal: 10)),
                    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 14, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily)),
                  ),
                  segments: [
                    ButtonSegment(value: 0, label: Text('Floating')),
                    ButtonSegment(value: 1, label: Text('Totals')),
                  ],
                  selected: {settings.damageDisplayMode},
                  onSelectionChanged: (selection) => settings.updateDamageDisplayMode(selection.first),
                ),
              ),

              // --- Armor Tracking ---
              SizedBox(height: 32),
              SizedBox(width: double.infinity, child: Text('Armor Tracking', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Show Armor Slots'),
                subtitle: Text('Track equipment defense on each player\'s side'),
                value: settings.armorTrackingEnabled,
                onChanged: (value) => settings.updateArmorTracking(value),
              ),

              // --- Tokens ---
              SizedBox(height: 32),
              Center(child: Text('Tokens', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => CustomTokenScreen(currentGame: settings.selectedGame),
                    ));
                  },
                  child: Text('Manage Custom Tokens'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
