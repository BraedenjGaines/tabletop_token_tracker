import "package:flutter/material.dart";
import "dart:math";

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
  int pOneHealth = 40;
  int pTwoHealth = 40;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Resource Tracker'),
        centerTitle: true, // Center the title in the app bar
      ),
      body: Column(
  children: [
    Expanded(
      child: Transform.rotate(
        angle: pi,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(onPressed: () {
                setState(() {
                  pOneHealth++;
                });
              }, child: Text('+')),
              Text('Life: $pOneHealth'),
              ElevatedButton(onPressed: () {
                setState(() {
                  pOneHealth--;
                });
              }, child: Text('-')),
            ],
          ),
        ),
      ),
    ),
    Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: () {
              setState(() {
                pTwoHealth++;
              });
            }, child: Text('+')),
            Text('Life: $pTwoHealth'),
            ElevatedButton(onPressed: () {
              setState(() {
                pTwoHealth--;
              });
            }, child: Text('-')),
          ],
        ),
      ),
    ),
  ],
),
    );
  }
}