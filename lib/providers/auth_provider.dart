// lib/providers/auth_provider.dart - IMPROVED VERSION with better auto-login
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoggedIn => isAuthenticated;
  bool get isInitialized => _isInitialized;

  // Initialize and check saved auth state
  Future<void> initializeAuth() async {
    debugPrint('🔄 AuthProvider.initializeAuth() START');
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedUserData = prefs.getString('user_data');
      
      if (savedToken != null && savedToken.isNotEmpty) {
        debugPrint('✅ Found saved token: ${savedToken.substring(0, 10)}...');
        
        // Try to validate token with server
        try {
          final userInfo = await _apiService.getProfile(savedToken);
          
          _token = savedToken;
          _user = Map<String, dynamic>.from(userInfo);
          
          // Update saved user data with latest from server
          await prefs.setString('user_data', json.encode(_user));
          
          debugPrint('✅ Auto-login successful with server validation');
        } catch (e) {
          debugPrint('❌ Token validation failed: $e');
          
          // Token is invalid, try using saved user data anyway
          if (savedUserData != null && savedUserData.isNotEmpty) {
            try {
              _token = savedToken;
              _user = json.decode(savedUserData);
              debugPrint('⚠️ Using saved user data without server validation');
            } catch (parseError) {
              debugPrint('❌ Failed to parse saved user data: $parseError');
              await _clearSavedAuth();
            }
          } else {
            await _clearSavedAuth();
          }
        }
      } else {
        debugPrint('❌ No saved authentication found');
      }
      
    } catch (e) {
      debugPrint('❌ InitializeAuth error: $e');
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
      debugPrint('✅ Auth initialization complete. isLoggedIn: $isLoggedIn');
    }
  }

  // Enhanced login method with better debugging
  Future<bool> login(String email, String password) async {
    debugPrint('🔄 AuthProvider.login() START');
    debugPrint('📧 Email: $email');
    
    _isLoading = true;
    notifyListeners();
    debugPrint('🔄 Set loading to true, notified listeners');

    try {
      debugPrint('🌐 Making API call...');
      final response = await _apiService.login(
        email: email,
        password: password,
      );
      
      debugPrint('✅ API response received');
      debugPrint('📊 Response keys: ${response.keys}');

      // Enhanced response validation
      if (response['token'] == null || response['token'].toString().isEmpty) {
        debugPrint('❌ No token in response');
        throw Exception('Server tidak mengembalikan token yang valid');
      }

      if (response['user'] == null) {
        debugPrint('❌ No user data in response');
        throw Exception('Server tidak mengembalikan data user');
      }

      _token = response['token'].toString();
      _user = Map<String, dynamic>.from(response['user']);
      
      debugPrint('✅ Token set: ${_token!.substring(0, 10)}...');
      debugPrint('✅ User data set: ${_user!.keys}');

      // Save to SharedPreferences with better error handling
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', json.encode(_user));
        debugPrint('✅ Data saved to SharedPreferences');
      } catch (e) {
        debugPrint('⚠️ Failed to save to SharedPreferences: $e');
      }

      _isLoading = false;
      debugPrint('🔄 Set loading to false');
      
      notifyListeners();
      debugPrint('🔔 Notified listeners - login complete');
      
      debugPrint('🔍 Final state check:');
      debugPrint('   isAuthenticated: $isAuthenticated');
      debugPrint('   isLoggedIn: $isLoggedIn');
      debugPrint('   token length: ${_token?.length}');
      debugPrint('   user not null: ${_user != null}');
      
      return true;
      
    } catch (e, stackTrace) {
      debugPrint('❌ Login error: $e');
      debugPrint('📋 Stack trace: $stackTrace');
      
      _isLoading = false;
      _token = null;
      _user = null;
      notifyListeners();
      
      // Enhance error messages
      if (e.toString().contains('SocketException')) {
        throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet.');
      } else if (e.toString().contains('TimeoutException')) {
        throw Exception('Koneksi timeout. Coba lagi.');
      } else if (e.toString().contains('401')) {
        throw Exception('Email atau password salah.');
      } else if (e.toString().contains('405')) {
        throw Exception('Server sedang maintenance. Coba lagi nanti.');
      } else if (e.toString().contains('422')) {
        throw Exception('Data tidak valid. Periksa format email dan password.');
      } else if (e.toString().contains('500')) {
        throw Exception('Server sedang bermasalah. Coba lagi nanti.');
      }
      
      rethrow;
    }
  }

  // Enhanced register method
  Future<bool> register(String name, String email, String password, String passwordConfirmation) async {
    debugPrint('🔄 AuthProvider.register() START');
    
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      debugPrint('✅ Register API response received');

      if (response['token'] == null || response['user'] == null) {
        throw Exception('Response tidak valid dari server');
      }

      _token = response['token'].toString();
      _user = Map<String, dynamic>.from(response['user']);

      // Save to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', json.encode(_user));
      } catch (e) {
        debugPrint('⚠️ Failed to save to SharedPreferences: $e');
      }

      _isLoading = false;
      notifyListeners();
      
      debugPrint('✅ Register complete');
      return true;
      
    } catch (e) {
      debugPrint('❌ Register error: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Enhanced auto-login (deprecated, use initializeAuth instead)
  Future<bool> tryAutoLogin() async {
    debugPrint('🔄 AuthProvider.tryAutoLogin() START');
    
    if (!_isInitialized) {
      await initializeAuth();
    }
    
    return isLoggedIn;
  }

  // Enhanced logout
  Future<void> logout() async {
    debugPrint('🔄 AuthProvider.logout() START');
    
    try {
      if (_token != null) {
        await _apiService.logout(_token!);
        debugPrint('✅ Server logout successful');
      }
    } catch (e) {
      debugPrint('⚠️ Server logout failed: $e');
    }

    await _clearSavedAuth();
    debugPrint('✅ Logout complete');
  }

  // Clear saved authentication data
  Future<void> _clearSavedAuth() async {
    // Clear local state
    _token = null;
    _user = null;

    // Clear SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      debugPrint('✅ Local data cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear SharedPreferences: $e');
    }

    notifyListeners();
  }

  // Enhanced load auth state (deprecated, use initializeAuth instead)
  Future<void> loadAuthState() async {
    debugPrint('🔄 AuthProvider.loadAuthState() START - Redirecting to initializeAuth');
    await initializeAuth();
  }

  // Enhanced update profile
  Future<void> updateProfile({String? name, String? email}) async {
    if (_token == null) {
      throw Exception('User not authenticated');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.updateProfile(_token!, name: name, email: email);
      
      // Get updated user info
      final userInfo = await _apiService.getProfile(_token!);
      _user = Map<String, dynamic>.from(userInfo);

      // Save updated user data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(_user));
      } catch (e) {
        debugPrint('⚠️ Failed to save updated user data: $e');
      }

      _isLoading = false;
      notifyListeners();
      
      debugPrint('✅ Profile updated successfully');
      
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Profile update error: $e');
      rethrow;
    }
  }

  // Enhanced refresh user data
  Future<void> refreshUser() async {
    if (_token == null) return;

    try {
      final userInfo = await _apiService.getProfile(_token!);
      _user = Map<String, dynamic>.from(userInfo);
      
      // Save refreshed user data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(_user));
      } catch (e) {
        debugPrint('⚠️ Failed to save refreshed user data: $e');
      }
          
      notifyListeners();
      debugPrint('✅ User data refreshed');
      
    } catch (e) {
      debugPrint('❌ Refresh user error: $e');
    }
  }

  // NEW: Refresh user data method (alias for refreshUser for compatibility)
  Future<void> refreshUserData() async {
    await refreshUser();
  }

  // NEW: Get user wallet data and update user state
  Future<void> refreshWalletData() async {
    if (_token == null) return;

    try {
      final walletData = await _apiService.getWallet(_token!);
      
      // Update user data with wallet info
      if (_user != null) {
        _user!['balance_rp'] = walletData['balance_rp'];
        _user!['balance_coins'] = walletData['balance_coins'];
        _user!['eco_coins'] = walletData['balance_coins']; // Alias for compatibility
        
        // Save updated user data
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', json.encode(_user));
        } catch (e) {
          debugPrint('⚠️ Failed to save wallet data: $e');
        }
        
        notifyListeners();
        debugPrint('✅ Wallet data refreshed');
      }
      
    } catch (e) {
      debugPrint('❌ Refresh wallet data error: $e');
    }
  }

  // NEW: Combined refresh method
  Future<void> refreshAllData() async {
    if (_token == null) return;

    try {
      // Refresh both user profile and wallet data
      final futures = await Future.wait([
        _apiService.getProfile(_token!),
        _apiService.getWallet(_token!),
      ]);
      
      final userInfo = Map<String, dynamic>.from(futures[0]);
      final walletData = Map<String, dynamic>.from(futures[1]);
      
      // Merge user and wallet data
      _user = Map<String, dynamic>.from(userInfo);
      _user!['balance_rp'] = walletData['balance_rp'];
      _user!['balance_coins'] = walletData['balance_coins'];
      _user!['eco_coins'] = walletData['balance_coins'];
      
      // Save all updated data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', json.encode(_user));
      } catch (e) {
        debugPrint('⚠️ Failed to save all refreshed data: $e');
      }
      
      notifyListeners();
      debugPrint('✅ All user data refreshed');
      
    } catch (e) {
      debugPrint('❌ Refresh all data error: $e');
    }
  }

  // Debug method to print current state
  void debugCurrentState() {
    debugPrint('🔍 === AUTH PROVIDER DEBUG STATE ===');
    debugPrint('   isAuthenticated: $isAuthenticated');
    debugPrint('   isLoggedIn: $isLoggedIn');
    debugPrint('   isLoading: $isLoading');
    debugPrint('   isInitialized: $isInitialized');
    debugPrint('   token: ${_token?.substring(0, 10)}...');
    debugPrint('   user: ${_user?.keys}');
    debugPrint('   user name: ${_user?['name']}');
    debugPrint('   user email: ${_user?['email']}');
    debugPrint('   user balance_rp: ${_user?['balance_rp']}');
    debugPrint('   user balance_coins: ${_user?['balance_coins']}');
    debugPrint('=====================================');
  }
}