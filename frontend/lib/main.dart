import 'package:flutter/material.dart';
import 'welcome_page.dart'; // Import the file we just made

void main() {
  runApp(const EchoVisionApp());
}

class EchoVisionApp extends StatelessWidget {
  const EchoVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EchoVision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        fontFamily: 'PatrickHand'
      ),
      home: const WelcomePage(),
    );
  }
}
