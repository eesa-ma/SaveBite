import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:save_bite/firebase_options.dart';
import 'package:save_bite/screens/home_screen.dart'; // Import the HomeScreen
import 'package:save_bite/screens/entry_screen.dart'; // Import the EntryScreen
import 'package:save_bite/screens/owner_dashboard.dart';
import 'package:save_bite/screens/admin_dashboard.dart';
import 'package:save_bite/screens/signup_screen.dart';
import 'package:save_bite/screens/profile_screen.dart';

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
      home: const EntryScreen(), // Set EntryScreen as the entry point
      routes: {
        '/login': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/entry': (context) => const EntryScreen(),
        '/owner': (context) => const OwnerDashboard(),
        '/admin': (context) => const AdminDashboard(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
