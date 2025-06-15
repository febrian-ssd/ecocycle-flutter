// lib/providers/auth_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart'; // <-- Perbaikan typo di sini
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecocycle_app/models/user.dart';
import 'package:ecocycle_app/services/mock_auth_service.dart';

class AuthProvider with ChangeNotifier { // <-- ChangeNotifier butuh import material.dart
  String? _token;
  User? _user;
  final MockAuthService _authService = MockAuthService();

  String? get token => _token;
  User? get user => _user;
  bool get isLoggedIn => _token != null;

  Future<bool> login(String email, String password) async {
    try {
      final response = await _authService.login(email, password);
      _token = response['access_token'];
      _user = User.fromJson(response['user']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('user', json.encode(_user!.toJson()));
      
      notifyListeners();
      return true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      return false;
    }

    _token = prefs.getString('token');
    _user = User.fromJson(json.decode(prefs.getString('user')!));
    notifyListeners();
    return true;
  }
}