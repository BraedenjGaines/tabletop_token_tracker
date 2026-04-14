import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  final String currentFont;
  final Function(String) onFontChanged;

  SettingsScreen({
    required this.currentFont,
    required this.onFontChanged,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String selectedFont;

  final List<String> availableFonts = [
    'Sedan',
    'EagleLake',
    'Jacquard12',
    'MedievalSharp',
  ];

  @override
  void initState() {
    super.initState();
    selectedFont = widget.currentFont;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Font',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: selectedFont,
                isExpanded: true,
                underline: SizedBox(),
                items: availableFonts.map((font) {
                  return DropdownMenuItem(
                    value: font,
                    child: Text(
                      font,
                      style: TextStyle(
                        fontFamily: font,
                        fontSize: 18,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newFont) {
                  if (newFont != null) {
                    setState(() {
                      selectedFont = newFont;
                    });
                    widget.onFontChanged(newFont);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}