import 'package:flutter/material.dart';
import 'theme.dart';              // <- your theme definitions
import 'screens/login.dart';     // <- your LoginPage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}): super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syllabuddy',
      debugShowCheckedModeBanner: false,
      theme: appTheme,           // <- apply your global theme
      home: const LoginPage(),   // <- render only your login screen here
    );
  }
}
