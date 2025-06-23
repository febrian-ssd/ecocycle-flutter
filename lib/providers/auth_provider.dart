// lib/providers/auth_provider.dart - FIXED VERSION (Remove unnecessary casts)
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
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoggedIn => isAuthenticated;

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
      debugPrint('📊 Response structure: ${response.runtimeType}');

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
      // FIXED: Remove unnecessary cast
      _user = Map<String, dynamic>.from(response['user']);
      
      debugPrint('✅ Token set: ${_token!.substring(0, 10)}...');
      debugPrint('✅ User data set: ${_user!.keys}');

      // Save to SharedPreferences with better error handling
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', _user.toString());
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
      // FIXED: Remove unnecessary cast
      _user = Map<String, dynamic>.from(response['user']);

      // Save to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', _user.toString());
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

  // Enhanced auto-login
  Future<bool> tryAutoLogin() async {
    debugPrint('🔄 AuthProvider.tryAutoLogin() START');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null || token.isEmpty) {
        debugPrint('❌ No saved token found');
        return false;
      }

      debugPrint('✅ Found saved token: ${token.substring(0, 10)}...');
      
      // Validate token with API
      try {
        final userInfo = await _apiService.getProfile(token);
        
        _token = token;
        _user = Map<String, dynamic>.from(userInfo);
            
        notifyListeners();
        
        debugPrint('✅ Auto-login successful');
        return true;
        
      } catch (e) {
        debugPrint('❌ Token validation failed: $e');
        
        // Clear invalid token
        await prefs.remove('auth_token');
        await prefs.remove('user_data');
        
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ Auto-login error: $e');
      return false;
    }
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
    debugPrint('✅ Logout complete');
  }

  // Enhanced load auth state
  Future<void> loadAuthState() async {
    debugPrint('🔄 AuthProvider.loadAuthState() START');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');

      if (_token != null && _token!.isNotEmpty) {
        debugPrint('✅ Found token: ${_token!.substring(0, 10)}...');
        
        try {
          final userInfo = await _apiService.getProfile(_token!);
          _user = Map<String, dynamic>.from(userInfo);
              
          notifyListeners();
          debugPrint('✅ Auth state loaded successfully');
          
        } catch (e) {
          debugPrint('❌ Failed to load user info: $e');
          await logout();
        }
      } else {
        debugPrint('❌ No valid token found');
      }
    } catch (e) {
      debugPrint('❌ LoadAuthState error: $e');
    }
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
      
      final userInfo = futures[0] as Map<String, dynamic>;
      final walletData = futures[1] as Map<String, dynamic>;
      
      // Merge user and wallet data
      _user = Map<String, dynamic>.from(userInfo);
      _user!['balance_rp'] = walletData['balance_rp'];
      _user!['balance_coins'] = walletData['balance_coins'];
      _user!['eco_coins'] = walletData['balance_coins'];
      
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
    debugPrint('   token: ${_token?.substring(0, 10)}...');
    debugPrint('   user: ${_user?.keys}');
    debugPrint('   user name: ${_user?['name']}');
    debugPrint('   user email: ${_user?['email']}');
    debugPrint('   user balance_rp: ${_user?['balance_rp']}');
    debugPrint('   user balance_coins: ${_user?['balance_coins']}');
    debugPrint('=====================================');
  }
}