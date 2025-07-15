import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart'; // Ensure this is imported

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat Me',
      theme: ThemeData(
        useMaterial3: true,
        // WhatsApp-like green
        colorSchemeSeed: Colors.green[700],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(), // Show SplashScreen first
    );
  }
}