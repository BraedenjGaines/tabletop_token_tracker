import "package:flutter/material.dart";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TableTop Token Tracker',
      home: CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  @override
  _CounterScreenState createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int health = 40;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resource Tracker'),
        centerTitle: true, // Center the title in the app bar
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, //Align the buttons and text in the center of the screen
          crossAxisAlignment: CrossAxisAlignment.center, //Align the buttons and text in the center of the screen
          children: [
            ElevatedButton(onPressed: () { //Increase health by 1 when the button is pressed
              setState(() {
                health++;
              });
            }, child: Text('+')),
            Text('Life: $health'), //Display the current health value
            ElevatedButton(onPressed: () { // Decrease health by 1 when the button is pressed
              setState(() {
                health--;
              });
            }, child: Text('-')),
          ],
        ),
      ),
    );
  }
}