import 'package:flutter/material.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Owner'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: const Center(
        child: Text(
          'Owner dashboard (placeholder)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
