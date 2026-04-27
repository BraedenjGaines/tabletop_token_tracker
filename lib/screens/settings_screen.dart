import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<GameSettingsProvider>();
    const descStyle = TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'CormorantGaramond');

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
              Center(child: Text('Turn Tracking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Enable Turn Tracking'),
                value: settings.turnTrackerEnabled,
                onChanged: (value) => settings.updateTurnTracker(value),
              ),
              Text('Displays a turn-by-turn phase bar between players. Some tokens are automatically destroyed when their trigger phase is reached.', style: descStyle),

              // --- Armor Tracking ---
              SizedBox(height: 32),
              Center(child: Text('Armor Tracking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Show equipment slot icons'),
                value: settings.armorTrackingEnabled,
                onChanged: (value) => settings.updateArmorTracking(value),
              ),
              Text('If you press and hold on an equipment slot, it will be destroyed. Tap it again to bring it back.', style: descStyle),

              // --- Add Token Button ---
              SizedBox(height: 32),
              Center(child: Text('Token Tracking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Show add token button'),
                value: settings.addTokenButtonEnabled,
                onChanged: (value) => settings.updateAddTokenButtonEnabled(value),
              ),
              Text('Displays a button that will allow you to add tokens to the board. Some tokens are automatically destroyed when their trigger phase is reached, and you have Turn Tracking enabled.', style: descStyle),

              // --- Clock ---
              SizedBox(height: 32),
              Center(child: Text('Match Timer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Show match timer'),
                value: settings.clockEnabled,
                onChanged: (value) => settings.updateClockEnabled(value),
              ),
              Text('Display a match timer that both players can start, pause, and reset.', style: descStyle),

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
              Text('Enables tracking for action points, pitch values, both, or none.', style: descStyle),

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
              Text('How the text will appear when taking or gaining health.', style: descStyle),

              // --- Frosted Glass ---
              SizedBox(height: 32),
              Center(child: Text('Blur Heroes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              SizedBox(height: 8),
              SwitchListTile(
                title: Text('Blur hero art'),
                value: settings.frostedGlass,
                onChanged: (value) => settings.updateFrostedGlass(value),
              ),
              Text('Applies a blur effect to the player panels for better visibility.', style: descStyle),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}