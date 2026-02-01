import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:save_bite/firebase_options.dart';
import 'package:save_bite/screens/login_screen.dart'; // Import the LoginScreen

void main() async {
  // Firebase initialization
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaveBite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2E7D32)),
      ),
      home: const LoginScreen(), // Set LoginScreen as the home screen
    );
  }
}
