import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/game_settings_provider.dart';
import 'screens/home_screen.dart';

class _NoOverscrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameSettingsProvider()..loadPreferences(),
      child: Consumer<GameSettingsProvider>(
        builder: (context, settings, _) {
          if (!settings.isLoaded) {
            return ScrollConfiguration(
              behavior: _NoOverscrollBehavior(),
              child: MaterialApp(
                home: Scaffold(body: Center(child: CircularProgressIndicator())),
              ),
            );
          }
          return MaterialApp(
            title: 'TableTop Token Tracker',
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: _NoOverscrollBehavior(),
                child: child!,
              );
            },
            debugShowCheckedModeBanner: false,
            themeMode: ThemeMode.dark,
            theme: ThemeData(
              fontFamily: settings.selectedFont,
              brightness: Brightness.dark,
              colorSchemeSeed: Colors.blue,
            ),
            darkTheme: ThemeData(
              fontFamily: settings.selectedFont,
              brightness: Brightness.dark,
              colorSchemeSeed: Colors.blue,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
