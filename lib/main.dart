import "package:flutter/material.dart";
void main() {
  runApp(MaterialApp(
    title: 'My App',
    home: Scaffold(
      appBar: AppBar(
        title: Text('Resource Tracker'),
      ),
      body: Center(
        child: Text('You have one million health!'),
      ),
    ),
  ));
}