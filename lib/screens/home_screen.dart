import 'package:flutter/material.dart';
import '../data/app_assets.dart';
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
  title: Image.asset(
    AppAssets.fleshAndBloodLogo,
    height: 200, // control size so it fits nicely
    fit: BoxFit.contain,
  ),
  centerTitle: true,
  backgroundColor: Colors.transparent,
  elevation: 0,
  toolbarHeight: 200,
),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.mapBackground,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: Colors.grey[900]),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MenuButton(
                  text: 'Play',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SetupScreen()));
                  },
                ),
                SizedBox(height: 20),
                _MenuButton(
                  text: 'Library',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CustomTokenScreen()));
                  },
                ),
                SizedBox(height: 20),
                _MenuButton(
                  text: 'Settings',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  },
                ),
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

class _MenuButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _MenuButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: 300,
        height: 55,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              AppAssets.playButton,
              width: 300,
              height: 45,
              fit: BoxFit.fill,
            ),
            Text(
              text,
              style: const TextStyle(
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
}
