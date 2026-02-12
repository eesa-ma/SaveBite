import 'package:flutter/material.dart';
import 'package:save_bite/services/auth_serivce.dart';
import 'package:save_bite/utils/sync_auth_to_firestore.dart';

/// Screen to help users who exist in Auth but not in Firestore
/// to complete their profile and sync to Firestore
class ProfileSyncScreen extends StatefulWidget {
  const ProfileSyncScreen({super.key});

  @override
  State<ProfileSyncScreen> createState() => _ProfileSyncScreenState();
}

class _ProfileSyncScreenState extends State<ProfileSyncScreen> {
  final AuthService _authService = AuthService();
  final SyncAuthToFirestore _syncService = SyncAuthToFirestore();
  final TextEditingController _nameController = TextEditingController();
  
  String _selectedRole = 'User';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _syncProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackbar('Please enter your name', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _syncService.syncCurrentUserToFirestore(
        name: _nameController.text.trim(),
        role: _selectedRole,
      );

      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      _showSnackbar(
        'Profile synced successfully!',
        const Color(0xFF2E7D32),
      );

      // Navigate to appropriate dashboard based on role
      final route = _routeForRole(_selectedRole);
      Navigator.of(context).pushNamedAndRemoveUntil(route, (r) => false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackbar(e.toString(), Colors.red);
      }
    }
  }

  String _routeForRole(String role) {
    switch (role) {
      case 'Restaurant':
        return '/owner';
      case 'Admin':
        return '/admin';
      case 'User':
      default:
        return '/entry';
    }
  }

  void _showSnackbar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.getCurrentUser();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.person_add,
                    size: 80,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'We need a few more details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your account (${user?.email ?? ''}) exists but we need to complete your profile.',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Select Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'User', child: Text('User')),
                      DropdownMenuItem(
                        value: 'Restaurant',
                        child: Text('Restaurant'),
                      ),
                      DropdownMenuItem(
                        value: 'Admin',
                        child: Text('Admin'),
                      ),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRole = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _syncProfile,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : const Text(
                              'Complete Profile',
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
