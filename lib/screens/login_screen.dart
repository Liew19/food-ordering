import 'package:flutter/material.dart';
import 'package:fyp/widgets/food_app_bar.dart';
import 'package:fyp/theme.dart';
import 'package:fyp/screens/signup_screen.dart';
import 'package:fyp/screens/forgot_password_screen.dart';
import 'package:provider/provider.dart';
import 'package:fyp/state/auth_provider.dart' as auth;
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    _checkQuickLogin();
  }

  Future<void> _checkQuickLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('login_token');
    final expiry = prefs.getInt('login_token_expiry');
    if (token != null && expiry != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < expiry) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
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
      ).signIn(email, password);

      // Save token and expiry for quick login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('login_token', 'valid');
      await prefs.setInt(
        'login_token_expiry',
        DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch,
      );

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
        } else if (error.contains('user-not-found')) {
          _emailError = 'No user found for this email.';
        } else {
          _passwordError = 'Incorrect password.';
        }
        _isLoading = false;
      });
    }
  }

  void _continueAsGuest() {
    // Navigate to main screen without authentication
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  void _navigateToSignUp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignupScreen()),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
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

              // Welcome Back text
              const Text(
                'Welcome Back',
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
                  border: OutlineInputBorder(),
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
              const SizedBox(height: 8),

              // General error message
              if (_generalError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _generalError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),

              // Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
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
                            'Log In',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 16),

              // Continue as guest button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _continueAsGuest,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.black87),
                  ),
                  GestureDetector(
                    onTap: _navigateToSignUp,
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Forgot password link
              GestureDetector(
                onTap: _navigateToForgotPassword,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
          // Disabled until logged in
        },
      ),
    );
  }
}
