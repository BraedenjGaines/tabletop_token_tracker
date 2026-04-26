import 'package:flutter/material.dart';
import 'setup_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'custom_token_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Flesh And Blood\nLife Counter',
          style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.white70, blurRadius: 10), Shadow(color: Colors.white54, blurRadius: 20)]),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/map_background.jpg',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCustomButton('Play', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SetupScreen()));
                }),
                SizedBox(height: 20),
                _buildCustomButton('Library', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomTokenScreen(currentGame: 'fab')));
                }),
                SizedBox(height: 20),
                _buildCustomButton('Settings', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                }),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: IconButton(
              icon: Icon(Icons.info_outline, color: Colors.white, size: 24),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildCustomButton(String text, VoidCallback onPressed) {
  return GestureDetector(
    onTap: onPressed,
    child: SizedBox(
      width: 300,
      height: 55,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/images/ui/play_button.png',
            width: 300,
            height: 45,
            fit: BoxFit.fill,
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ),
    ),
  );
}
