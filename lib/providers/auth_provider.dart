// lib/providers/auth_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecocycle_app/models/user.dart';
import 'package:ecocycle_app/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  User? _user;
  final ApiService _apiService = ApiService();

  String? get token => _token;
  User? get user => _user;
  bool get isLoggedIn => _token != null && _user != null;

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      _token = response['access_token'];
      _user = User.fromJson(response['user']);
      await _saveAuthData();
      notifyListeners();
    } catch (e) {
      // Re-throw dengan pesan yang lebih user-friendly
      if (e.toString().contains('credentials do not match')) {
        throw Exception('Email atau password salah');
      } else if (e.toString().contains('Network error')) {
        throw Exception('Tidak dapat terhubung ke server');
      } else {
        throw Exception('Login gagal: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.register(name, email, password);
      _token = response['access_token'];
      _user = User.fromJson(response['user']);
      await _saveAuthData();
      notifyListeners();
    } catch (e) {
      // Re-throw dengan pesan yang lebih user-friendly
      if (e.toString().contains('email has already been taken')) {
        throw Exception('Email sudah digunakan');
      } else if (e.toString().contains('Network error')) {
        throw Exception('Tidak dapat terhubung ke server');
      } else {
        throw Exception('Registrasi gagal: ${e.toString().replaceFirst('Exception: ', '')}');
      }
    }
  }

  Future<void> logout() async {
    try {
      // Panggil API logout jika ada token
      if (_token != null) {
        await _apiService.logout(_token!);
      }
    } catch (e) {
      // Jika API logout gagal, tetap lanjutkan logout lokal
      debugPrint('Logout API failed: $e');
    } finally {
      // Hapus data lokal
      _token = null;
      _user = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      notifyListeners();
    }
  }

  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('user', json.encode(_user!.toJson()));
  }

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!prefs.containsKey('token') || !prefs.containsKey('user')) {
        return false;
      }
      
      final token = prefs.getString('token');
      final userJson = prefs.getString('user');
      
      if (token == null || userJson == null) {
        return false;
      }

      // Verify token dengan server
      try {
        final userInfo = await _apiService.getUserInfo(token);
        _token = token;
        _user = User.fromJson(userInfo);
        notifyListeners();
        return true;
      } catch (e) {
        // Token tidak valid, hapus data lokal
        await prefs.clear();
        return false;
      }
    } catch (e) {
      debugPrint('Auto login error: $e');
      return false;
    }
  }

  // Method untuk refresh user data
  Future<void> refreshUserData() async {
    if (_token == null) return;
    
    try {
      final userInfo = await _apiService.getUserInfo(_token!);
      _user = User.fromJson(userInfo);
      await _saveAuthData();
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh user data error: $e');
    }
  }

  // Method untuk update user info lokal (misalnya setelah transfer/tukar koin)
  void updateLocalBalance({double? balanceRp, int? balanceCoins}) {
    if (_user == null) return;
    
    // Note: Karena User model tidak memiliki balance fields,
    // kita hanya refresh dari server untuk data terbaru
    refreshUserData();
  }
}