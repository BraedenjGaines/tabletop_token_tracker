import 'package:flutter/material.dart';
import 'counter_screen.dart';

class SetupScreen extends StatefulWidget {
  final String selectedFont;
  final Function(String) onFontChanged;

  SetupScreen({
    required this.selectedFont,
    required this.onFontChanged,
  });

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int selectedPlayers = 2;
  int selectedLife = 20;
  bool isCustomLife = false;
  final TextEditingController customLifeController = TextEditingController();

  @override
  void dispose() {
    customLifeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Setup'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Number of Players'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 2; i <= 6; i++)
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedPlayers = i;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            selectedPlayers == i ? Colors.blue : Colors.grey,
                      ),
                      child: Text('$i'),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 30),
            Text('Starting Life'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int life in [20, 25, 30, 40])
                  Padding(
                    padding: EdgeInsets.all(4),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedLife = life;
                          isCustomLife = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isCustomLife && selectedLife == life
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      child: Text('$life'),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(4),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isCustomLife = true;
                        selectedLife =
                            int.tryParse(customLifeController.text) ?? 0;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCustomLife ? Colors.blue : Colors.grey,
                    ),
                    child: Text('Custom'),
                  ),
                ),
              ],
            ),
            if (isCustomLife)
              Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 100,
                  child: TextField(
                    controller: customLifeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter life',
                    ),
                    onChanged: (value) {
                      setState(() {
                        selectedLife = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
              ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: selectedLife >= 1
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CounterScreen(
                            playerCount: selectedPlayers,
                            startingLife: selectedLife,
                            selectedFont: widget.selectedFont,
                            onFontChanged: widget.onFontChanged,
                          ),
                        ),
                      );
                    }
                  : null,
              child: Text('Start Game'),
            ),
          ],
        ),
      ),
    );
  }
}