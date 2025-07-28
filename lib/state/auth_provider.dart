import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppAuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  String? _role;
  bool _isLoading = true;

  AppAuthProvider() {
    _init();
  }

  User? get user => _user;
  String? get role => _role;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _role == 'admin';
  bool get isKitchenStaff => _role == 'kitchen';
  bool get isStaff => _role == 'staff';
  bool get isCustomer => _role == 'customer';

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) async {
      _user = user;

      if (user != null) {
        // Fetch user role from Firestore
        try {
          final doc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
          if (doc.exists) {
            _role = doc.data()?['role'] as String?;
          }
        } catch (e) {
          _role = null;
        }
      } else {
        _role = null;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<void> signUp(String email, String password, String role) async {
    try {
      await _authService.createUserWithEmailAndPassword(email, password, role);
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      _user = null;
      _role = null;
      // Clear quick login token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('login_token');
      await prefs.remove('login_token_expiry');
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      rethrow;
    }
  }
}
