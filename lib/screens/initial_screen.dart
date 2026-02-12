import 'package:flutter/material.dart';
import '../services/auth_serivce.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Small delay for smooth transition
    await Future.delayed(const Duration(milliseconds: 500));

    final user = _authService.getCurrentUser();

    if (!mounted) return;

    if (user == null) {
      // No user logged in, go to entry screen
      Navigator.of(context).pushReplacementNamed('/entry');
      return;
    }

    // User is logged in, check if they exist in Firestore
    final exists = await _authService.userExistsInFirestore(user.uid);

    if (!mounted) return;

    if (!exists) {
      // User exists in Auth but not in Firestore
      Navigator.of(context).pushReplacementNamed('/profile-sync');
      return;
    }

    // Get user role from Firestore
    final userData = await _authService.getUserData(user.uid);

    if (!mounted) return;

    if (userData == null || userData['role'] == null) {
      // No role data, redirect to profile sync
      Navigator.of(context).pushReplacementNamed('/profile-sync');
      return;
    }

    // Route based on role
    final role = userData['role'];
    String route;
    switch (role) {
      case 'Restaurant':
        route = '/restaurant';
        break;
      case 'Admin':
        route = '/admin';
        break;
      case 'User':
      default:
        route = '/entry';
        break;
    }

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'SaveBite',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Reducing Food Waste, One Meal at a Time',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
