import 'package:flutter/material.dart';
import 'package:save_bite/services/auth_serivce.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedRole = 'User';
  bool _isLoading = false;
  bool _isLogin = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['role'] is String) {
      _selectedRole = _normalizeRole(args['role'] as String);
    }
  }

  String _normalizeRole(String role) {
    switch (role.toLowerCase()) {
      case 'restaurant':
        return 'Restaurant';
      case 'admin':
        return 'Admin';
      case 'customer':
      case 'user':
      default:
        return 'User';
    }
  }

  void _submitAuth() async {
    if (_emailController.text.trim().isEmpty) {
      _showSnackbar('Please enter your email', Colors.red);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackbar('Password must be at least 6 characters', Colors.red);
      return;
    }

    if (!_isLogin && _nameController.text.trim().isEmpty) {
      _showSnackbar('Please enter your name', Colors.red);
      return;
    }

    if (!_isLogin &&
        _passwordController.text != _confirmPasswordController.text) {
      _showSnackbar('Passwords do not match', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await _authService.login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _showSnackbar(
        _isLogin
            ? 'Login successful as $_selectedRole!'
            : 'Account created successfully as $_selectedRole!',
        const Color(0xFF2E7D32),
      );

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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Light grey background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isLogin
                        ? 'Login to continue'
                        : 'Join SaveBite and reduce food waste',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  if (!_isLogin)
                    Column(
                      children: [
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
                      ],
                    ),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!_isLogin)
                    Column(
                      children: [
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
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
                      onPressed: _isLoading ? null : _submitAuth,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: const Color(0xFF2E7D32), // Deep green
                        foregroundColor: Colors.white, // Text color
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                          : Text(
                              _isLogin ? 'Login' : 'Sign Up',
                              style: const TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                    child: Text(
                      _isLogin
                          ? "Don't have an account? Sign up"
                          : 'Already have an account? Login',
                      style: const TextStyle(color: Color(0xFF2E7D32)),
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