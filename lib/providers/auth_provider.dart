import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  User? get firebaseUser => _authService.currentUser;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _user = await _authService.getUserById(firebaseUser.uid);
      } else {
        _user = null;
      }
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newUser = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      if (newUser != null) {
        _user = newUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to create user account';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Extract error message, removing "Exception: " prefix if present
      final errorMessage = e.toString().replaceFirst(
        RegExp(r'^Exception:\s*'),
        '',
      );
      _error = errorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final signedInUser = await _authService.signIn(
        email: email,
        password: password,
      );

      if (signedInUser != null) {
        _user = signedInUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'User profile not found. Please contact support.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      // Extract error message, removing "Exception: " prefix if present
      final errorMessage = e.toString().replaceFirst(
        RegExp(r'^Exception:\s*'),
        '',
      );
      _error = errorMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _authService.clearCache();
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> refreshUser() async {
    if (_authService.currentUser != null) {
      _user = await _authService.getUserById(_authService.currentUser!.uid);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
