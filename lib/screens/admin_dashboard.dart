import 'package:flutter/material.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: const Center(
        child: Text(
          'Admin dashboard (placeholder)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
