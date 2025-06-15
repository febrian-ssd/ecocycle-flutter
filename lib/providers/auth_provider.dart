// lib/providers/auth_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecocycle_app/models/user.dart';
import 'package:ecocycle_app/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  final ApiService _apiService = ApiService(); // Gunakan ApiService asli

  String? get token => _token;
  User? get user => _user;
  bool get isLoggedIn => _token != null;

  Future<void> login(String email, String password) async {
    final response = await _apiService.login(email, password);
    _token = response['access_token'];
    _user = User.fromJson(response['user']);
    await _saveAuthData();
    notifyListeners();
  }

  Future<void> register(String name, String email, String password) async {
    final response = await _apiService.register(name, email, password);
    _token = response['access_token'];
    _user = User.fromJson(response['user']);
    await _saveAuthData();
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('user', json.encode(_user!.toJson()));
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token') || !prefs.containsKey('user')) {
      return false;
    }
    _token = prefs.getString('token');
    _user = User.fromJson(json.decode(prefs.getString('user')!));
    notifyListeners();
    return true;
  }
}