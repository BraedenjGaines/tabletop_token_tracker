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
              // --- Theme ---
              SizedBox(height: 16),
              Center(child: Text('Choose a theme:', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              SizedBox(height: 12),
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

              // --- Turn Tracker ---
              SizedBox(height: 32),
              Center(child: Text('Turn Tracking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Enable Turn Tracking'),
                value: settings.turnTrackerEnabled,
                onChanged: (value) => settings.updateTurnTracker(value),
              ),
              Text('Displays a turn-by-turn phase bar between players. Some tokens are automatically destroyed when their trigger phase is reached.', style: TextStyle(fontSize: 13, color: Colors.grey)),

              // --- Resource Tracking ---
              SizedBox(height: 32),
              Center(child: Text('Resource Tracking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
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
              SizedBox(height: 8),
              Text('Enables tracking for action points, pitch values, both, or none.', style: TextStyle(fontSize: 13, color: Colors.grey)),

              // --- Armor Tracking ---
              SizedBox(height: 32),
              Center(child: Text('Armor Tracking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Show equipment slot icons'),
                value: settings.armorTrackingEnabled,
                onChanged: (value) => settings.updateArmorTracking(value),
              ),

              // --- Combat Text ---
              SizedBox(height: 32),
              Center(child: Text('Combat Text', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16, horizontal: 10)),
                    textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 14, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily)),
                  ),
                  segments: [
                    ButtonSegment(value: 0, label: Text('Cascading')),
                    ButtonSegment(value: 1, label: Text('Fixed')),
                  ],
                  selected: {settings.damageDisplayMode},
                  onSelectionChanged: (selection) => settings.updateDamageDisplayMode(selection.first),
                ),
              ),
              SizedBox(height: 8),
              Text('How the text will appear when taking or gaining health.', style: TextStyle(fontSize: 13, color: Colors.grey)),

              // --- Frosted Glass ---
              SizedBox(height: 32),
              Center(child: Text('Visual', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Frosted Glass Effect'),
                subtitle: Text('Applies a frosted glass blur effect to the player panels on the counter screen'),
                value: settings.frostedGlass,
                onChanged: (value) => settings.updateFrostedGlass(value),
              ),

              // --- Custom Tokens ---
              SizedBox(height: 32),
              Center(child: Text('Custom Tokens', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
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
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
