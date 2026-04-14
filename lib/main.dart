import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String selectedFont = 'Sedan';
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFont();
  }

  Future<void> _loadFont() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedFont = prefs.getString('selectedFont') ?? 'Sedan';
      isLoaded = true;
    });
  }

  Future<void> _saveFont() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedFont', selectedFont);
  }

  void updateFont(String newFont) {
    setState(() {
      selectedFont = newFont;
    });
    _saveFont();
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoaded) {
      return MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    return MaterialApp(
      title: 'TableTop Token Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: selectedFont,
      ),
      home: HomeScreen(
        selectedFont: selectedFont,
        onFontChanged: updateFont,
      ),
    );
  }
}