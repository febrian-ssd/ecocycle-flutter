import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecocycle_app/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  // Login method - FIXED: Added named parameters
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      _token = response['token'];
      _user = response['user'];

      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', response['user'].toString());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Register method - FIXED: Added named parameters
  Future<bool> register(String name, String email, String password, String passwordConfirmation) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      _token = response['token'];
      _user = response['user'];

      // Save token to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', response['user'].toString());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      if (_token != null) {
        await _apiService.logout(_token!);
      }
    } catch (e) {
      // Continue with logout even if API call fails
      print('Error during logout: $e');
    }

    _token = null;
    _user = null;

    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');

    notifyListeners();
  }

  // Load saved authentication state
  Future<void> loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    if (_token != null) {
      try {
        // Get fresh user info from API - FIXED: Use getProfile instead of getUserInfo
        final userInfo = await _apiService.getProfile(_token!);
        _user = userInfo;
        notifyListeners();
      } catch (e) {
        // Token might be expired, clear it
        await logout();
      }
    }
  }

  // Update user profile
  Future<void> updateProfile({String? name, String? email}) async {
    if (_token == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Update profile via API - FIXED: Use getProfile instead of getUserInfo
      await _apiService.updateProfile(_token!, name: name, email: email);
      
      // Get updated user info
      final userInfo = await _apiService.getProfile(_token!);
      _user = userInfo;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    if (_token == null) return;

    try {
      final userInfo = await _apiService.getProfile(_token!);
      _user = userInfo;
      notifyListeners();
    } catch (e) {
      print('Error refreshing user: $e');
    }
  }
}