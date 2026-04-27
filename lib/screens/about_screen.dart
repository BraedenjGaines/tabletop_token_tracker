import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            Text('TableTop Token Tracker', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text('Version 1.0', style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 24),
            Text(
              'This is a fan made app designed to help track tokens, life totals, and other game elements for various tabletop card games. I hope it makes your games more enjoyable!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Please feel free to send any feedback or suggestions you have!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            SizedBox(
              width: 240,
              height: 70,
              child: ElevatedButton(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite, color: Colors.red, size: 30),
                    SizedBox(width: 12),
                    Text('Support the\nDeveloper', style: TextStyle(fontSize: 20), textAlign: TextAlign.center),
                  ],
                ),
                onPressed: () {
                  launchUrl(Uri.parse('https://buymeacoffee.com/braedenjgaines'), mode: LaunchMode.externalApplication);
                },
              ),
            ),
            SizedBox(height: 32),
            GestureDetector(
              onTap: () {
                launchUrl(Uri.parse('https://github.com/BraedenjGaines/tabletop_token_tracker'), mode: LaunchMode.externalApplication);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.code, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('GitHub Repository', style: TextStyle(fontSize: 14, color: Colors.blue, decoration: TextDecoration.underline)),
                ],
              ),
            ),
            SizedBox(height: 32),
            Divider(),
            SizedBox(height: 16),
            Text(
              '© 2026 Braeden Gaines. All Rights Reserved.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'This app is not affiliated with, endorsed by, or sponsored by Legend Story Studios or any other game company. Flesh and Blood is a trademark of Legend Story Studios.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
