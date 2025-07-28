import 'package:flutter/material.dart';
import 'package:fyp/widgets/food_app_bar.dart';
import 'package:fyp/theme.dart';
import 'package:fyp/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:fyp/state/auth_provider.dart' as auth;
import '../main.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _generalError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    bool hasError = false;

    // Local validation
    if (email.isEmpty) {
      _emailError = 'Email cannot be empty';
      hasError = true;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _emailError = 'Invalid email format';
      hasError = true;
    }
    if (password.isEmpty) {
      _passwordError = 'Password cannot be empty';
      hasError = true;
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      hasError = true;
    }
    if (confirmPassword != password) {
      _confirmPasswordError = 'Passwords do not match';
      hasError = true;
    }
    if (hasError) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await Provider.of<auth.AppAuthProvider>(
        context,
        listen: false,
      ).signUp(email, password, 'customer'); // Force customer role

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } catch (e) {
      String error = e.toString();
      setState(() {
        if (error.contains('invalid-email')) {
          _emailError = 'Invalid email address.';
        } else if (error.contains('email-already-in-use')) {
          _emailError = 'This email is already in use.';
        } else if (error.contains('weak-password')) {
          _passwordError = 'Password is too weak.';
        } else {
          _generalError = 'An error occurred during sign up.';
        }
        _isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FoodAppBar(showSearch: false),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Restaurant icon placeholder
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),

              // Create Account text
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),

              // Email field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  errorText: _emailError,
                ),
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),

              // Password field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  errorText: _passwordError,
                ),
                obscureText: true,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),

              // Confirm Password field
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  errorText: _confirmPasswordError,
                ),
                obscureText: true,
                style: const TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 16),

              // General error message
              if (_generalError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _generalError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // Role selection dropdown
              // Removed as per edit hint
              const SizedBox(height: 24),

              // Sign Up button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: AppTheme.primaryButtonStyle,
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 24),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.black87),
                  ),
                  GestureDetector(
                    onTap: _navigateToLogin,
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Kitchen'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Staff'),
        ],
        currentIndex: 0,
        onTap: (_) {
          // Disabled until signed up
        },
      ),
    );
  }
}
