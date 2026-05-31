import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const TreningApp());
}

class TreningApp extends StatelessWidget {
  const TreningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moj Trening',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // tamnozelena
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}