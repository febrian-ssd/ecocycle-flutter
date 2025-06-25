// lib/providers/auth_provider.dart - COMPLETE VERSION WITH ALL MISSING METHODS
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // State variables
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _wallet;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _hasWalletError = false;
  
  // Getters
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get wallet => _wallet;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isAuthenticated => isLoggedIn;
  String? get errorMessage => _errorMessage;
  bool get hasWalletError => _hasWalletError;
  
  // Helper getters for wallet data with fallback values
  double get balanceRp {
    if (_wallet == null || _hasWalletError) return 0.0;
    
    // Try different possible keys for balance
    final data = _wallet!['data'] ?? _wallet!;
    return ConversionUtils.toDouble(
      data['balance_rp'] ?? 
      data['balance'] ?? 
      data['saldo_rp'] ?? 
      0
    );
  }
  
  int get balanceKoin {
    if (_wallet == null || _hasWalletError) return 0;
    
    // Try different possible keys for coins
    final data = _wallet!['data'] ?? _wallet!;
    return ConversionUtils.toInt(
      data['balance_koin'] ?? 
      data['coins'] ?? 
      data['koin'] ?? 
      0
    );
  }

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    debugPrint('🔄 AuthProvider._initializeAuth() START');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedUserJson = prefs.getString('user_data');
      
      if (savedToken != null && savedUserJson != null) {
        debugPrint('🔍 Found saved auth data, attempting to restore session');
        _token = savedToken;
        
        try {
          // Try to verify token is still valid by getting user data
          await _loadUserData();
          
          debugPrint('✅ Session restored successfully');
        } catch (e) {
          debugPrint('❌ Saved session invalid, clearing data: $e');
          await _clearLocalData();
        }
      } else {
        debugPrint('ℹ️ No saved auth data found');
      }
    } catch (e) {
      debugPrint('❌ Error initializing auth: $e');
      await _clearLocalData();
    } finally {
      _isInitialized = true;
      debugPrint('✅ AuthProvider initialization complete');
      notifyListeners();
    }
  }

  // PUBLIC METHOD: Initialize auth (called from main.dart and auth_wrapper.dart)
  Future<void> initializeAuth() async {
    await _initializeAuth();
  }

  Future<void> login(String email, String password) async {
    debugPrint('🔐 AuthProvider.login() START');
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final response = await _apiService.login(email, password);
      
      _token = response['token'] ?? response['access_token'];
      if (_token == null) {
        throw Exception('Token tidak ditemukan dalam respons server');
      }
      
      debugPrint('✅ Login successful, token received');
      
      // Load user data and wallet data
      await _loadUserData();
      
      // Save to local storage
      await _saveToLocalStorage();
      
      debugPrint('✅ Login process complete');
      
    } catch (e) {
      debugPrint('❌ Login failed: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      await _clearLocalData();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(Map<String, String> userData) async {
    debugPrint('👤 AuthProvider.register() START');
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final response = await _apiService.register(userData);
      
      _token = response['token'] ?? response['access_token'];
      if (_token == null) {
        throw Exception('Token tidak ditemukan dalam respons server');
      }
      
      debugPrint('✅ Registration successful, token received');
      
      // Load user data and wallet data
      await _loadUserData();
      
      // Save to local storage
      await _saveToLocalStorage();
      
      debugPrint('✅ Registration process complete');
      
    } catch (e) {
      debugPrint('❌ Registration failed: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      await _clearLocalData();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    debugPrint('🔄 AuthProvider.logout() START');
    _setLoading(true);
    
    try {
      if (_token != null) {
        try {
          await _apiService.logout(_token!);
          debugPrint('✅ Server logout successful');
        } catch (e) {
          debugPrint('⚠️ Server logout failed, continuing with local logout: $e');
        }
      }
      
      await _clearLocalData();
      debugPrint('✅ Local data cleared');
      
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      // Still clear local data even if server logout fails
      await _clearLocalData();
    } finally {
      _setLoading(false);
      debugPrint('✅ Logout complete');
    }
  }

  // Enhanced user data loading with better error handling
  Future<void> _loadUserData() async {
    if (_token == null) {
      throw Exception('Token tidak tersedia');
    }
    
    debugPrint('👤 Loading user data...');
    
    try {
      // Load user profile
      final userResponse = await _apiService.getUser(_token!);
      _user = userResponse['user'] ?? userResponse['data'] ?? userResponse;
      
      debugPrint('✅ User data loaded successfully');
      
      // Load wallet data with graceful error handling
      await _loadWalletData();
      
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      
      // If it's an auth error, clear everything
      if (e.toString().contains('401') || e.toString().contains('Unauthenticated')) {
        await _clearLocalData();
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }
      
      rethrow;
    }
  }

  // Enhanced wallet data loading with graceful fallback
  Future<void> _loadWalletData() async {
    if (_token == null) return;
    
    debugPrint('💰 Loading wallet data...');
    _hasWalletError = false;
    
    try {
      final walletResponse = await _apiService.getWallet(_token!);
      
      // Check if this is a fallback response due to missing endpoint
      if (walletResponse['success'] == false && 
          walletResponse['message']?.contains('unavailable') == true) {
        debugPrint('⚠️ Wallet service unavailable, using default values');
        _wallet = {
          'balance_rp': 0,
          'balance_koin': 0,
          'data': {
            'balance_rp': 0,
            'balance_koin': 0,
          }
        };
        _hasWalletError = true;
      } else {
        _wallet = walletResponse;
        debugPrint('✅ Wallet data loaded successfully');
      }
      
    } catch (e) {
      debugPrint('❌ Error loading wallet data: $e');
      
      // Set default wallet values and mark as having error
      _wallet = {
        'balance_rp': 0,
        'balance_koin': 0,
        'data': {
          'balance_rp': 0,
          'balance_koin': 0,
        }
      };
      _hasWalletError = true;
      
      debugPrint('⚠️ Using default wallet values due to error');
    }
  }

  // Public method to refresh all data
  Future<void> refreshAllData() async {
    debugPrint('🔄 Refreshing all user data...');
    
    if (_token == null) {
      debugPrint('❌ Cannot refresh data: no token available');
      return;
    }
    
    try {
      await _loadUserData();
      debugPrint('✅ Data refresh complete');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
      
      // If it's an auth error, handle gracefully
      if (e.toString().contains('401') || e.toString().contains('Unauthenticated')) {
        _errorMessage = 'Sesi berakhir. Silakan login kembali.';
        await logout();
      } else {
        _errorMessage = 'Gagal memuat data terbaru';
      }
      
      notifyListeners();
    }
  }

  // Public method to refresh only wallet data
  Future<void> refreshWalletData() async {
    debugPrint('💰 Refreshing wallet data...');
    
    if (_token == null) {
      debugPrint('❌ Cannot refresh wallet: no token available');
      return;
    }
    
    try {
      await _loadWalletData();
      debugPrint('✅ Wallet refresh complete');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error refreshing wallet: $e');
      _errorMessage = 'Gagal memuat data wallet';
      notifyListeners();
    }
  }

  // UPDATE PROFILE METHOD (for edit_profile_screen.dart)
  Future<void> updateProfile(Map<String, String> userData) async {
    debugPrint('📝 Updating user profile...');
    _setLoading(true);
    _errorMessage = null;
    
    try {
      if (_token == null) {
        throw Exception('Token tidak tersedia');
      }
      
      // Call API to update profile
      await _apiService.updateProfile(_token!, userData);
      
      // Reload user data to get updated info
      await _loadUserData();
      
      debugPrint('✅ Profile updated successfully');
      
    } catch (e) {
      debugPrint('❌ Profile update failed: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // DEBUG CURRENT STATE METHOD (for auth_wrapper.dart)
  void debugCurrentState() {
    debugPrint('🔍 AuthProvider state in AuthWrapper:');
    debugPrint('   isLoggedIn: $isLoggedIn');
    debugPrint('   isAuthenticated: $isAuthenticated');
    debugPrint('   isLoading: $isLoading');
    debugPrint('   isInitialized: $isInitialized');
    debugPrint('   token: ${_token?.substring(0, 10) ?? 'null'}...');
    debugPrint('   user: ${_user != null ? 'loaded' : 'null'}');
    debugPrint('   wallet: ${_wallet != null ? 'loaded' : 'null'}');
    debugPrint('   hasWalletError: $hasWalletError');
  }

  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_token != null) {
        await prefs.setString('auth_token', _token!);
      }
      
      if (_user != null) {
        await prefs.setString('user_data', _user.toString());
      }
      
      debugPrint('✅ Data saved to local storage');
    } catch (e) {
      debugPrint('❌ Error saving to local storage: $e');
    }
  }

  Future<void> _clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
      
      _token = null;
      _user = null;
      _wallet = null;
      _errorMessage = null;
      _hasWalletError = false;
      
      debugPrint('✅ Local data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing local data: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get wallet status message for UI
  String getWalletStatusMessage() {
    if (_hasWalletError) {
      return 'Layanan wallet sedang dalam pengembangan. Beberapa fitur mungkin tidak tersedia.';
    }
    return '';
  }

  // Check if wallet features are available
  bool get isWalletAvailable => !_hasWalletError;
}