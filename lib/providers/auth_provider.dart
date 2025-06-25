// lib/providers/auth_provider.dart - Enhanced with Role Management
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/models/user.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  // State variables
  User? _user;
  Map<String, dynamic>? _wallet;
  String? _token;
  List<String> _abilities = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _hasWalletError = false;
  
  // Getters
  User? get user => _user;
  Map<String, dynamic>? get wallet => _wallet;
  String? get token => _token;
  List<String> get abilities => _abilities;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isAuthenticated => isLoggedIn;
  String? get errorMessage => _errorMessage;
  bool get hasWalletError => _hasWalletError;
  
  // Role-based getters
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isUser => _user?.isUser ?? false;
  String get userRole => _user?.role ?? 'unknown';
  String get userRoleDisplay => _user?.roleDisplay ?? 'Unknown';
  
  // Helper getters for wallet data with fallback values
  double get balanceRp {
    if (_wallet == null || _hasWalletError) return 0.0;
    
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
    
    final data = _wallet!['data'] ?? _wallet!;
    return ConversionUtils.toInt(
      data['balance_koin'] ?? 
      data['coins'] ?? 
      data['koin'] ?? 
      0
    );
  }

  // Permission checking
  bool hasPermission(String permission) {
    return _abilities.contains(permission);
  }

  bool hasRole(String role) {
    return _user?.role == role;
  }

  bool hasAnyRole(List<String> roles) {
    return roles.contains(_user?.role);
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
      final savedAbilitiesJson = prefs.getString('user_abilities');
      
      if (savedToken != null && savedUserJson != null) {
        debugPrint('🔍 Found saved auth data, attempting to restore session');
        _token = savedToken;
        
        // Parse saved user data
        try {
          final userMap = Map<String, dynamic>.from(
            Map.from(Uri.splitQueryString(savedUserJson))
          );
          _user = User.fromJson(userMap);
          
          if (savedAbilitiesJson != null) {
            _abilities = List<String>.from(
              Uri.splitQueryString(savedAbilitiesJson).keys
            );
          }
          
          // Verify token is still valid
          await _verifyToken();
          
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

  // PUBLIC METHOD: Initialize auth
  Future<void> initializeAuth() async {
    await _initializeAuth();
  }

  Future<void> login(String email, String password) async {
    debugPrint('🔐 AuthProvider.login() START for role-based auth');
    _setLoading(true);
    _errorMessage = null;
    
    try {
      final response = await _apiService.login(email, password);
      
      if (!response['success']) {
        throw Exception(response['message'] ?? 'Login failed');
      }
      
      final data = response['data'];
      _token = data['access_token'];
      _abilities = List<String>.from(data['abilities'] ?? []);
      
      if (_token == null) {
        throw Exception('Token tidak ditemukan dalam respons server');
      }
      
      // Parse user data
      final userData = data['user'];
      _user = User.fromJson(userData);
      
      debugPrint('✅ Login successful, role: ${_user?.role}');
      debugPrint('✅ User abilities: $_abilities');
      
      // Load wallet data
      await _loadWalletData();
      
      // Save to local storage
      await _saveToLocalStorage();
      
      debugPrint('✅ Login process complete for ${_user?.roleDisplay}');
      
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
      
      if (!response['success']) {
        throw Exception(response['message'] ?? 'Registration failed');
      }
      
      final data = response['data'];
      _token = data['access_token'];
      _abilities = List<String>.from(data['abilities'] ?? []);
      
      if (_token == null) {
        throw Exception('Token tidak ditemukan dalam respons server');
      }
      
      // Parse user data
      final userDataResponse = data['user'];
      _user = User.fromJson(userDataResponse);
      
      debugPrint('✅ Registration successful, role: ${_user?.role}');
      
      // Load wallet data
      await _loadWalletData();
      
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
      await _clearLocalData();
    } finally {
      _setLoading(false);
      debugPrint('✅ Logout complete');
    }
  }

  // Enhanced user data loading
  Future<void> _loadUserData() async {
    if (_token == null) {
      throw Exception('Token tidak tersedia');
    }
    
    debugPrint('👤 Loading user data...');
    
    try {
      final userResponse = await _apiService.getUser(_token!);
      
      if (!userResponse['success']) {
        throw Exception(userResponse['message'] ?? 'Failed to load user data');
      }
      
      final userData = userResponse['data']['user'];
      _user = User.fromJson(userData);
      
      debugPrint('✅ User data loaded successfully, role: ${_user?.role}');
      
      await _loadWalletData();
      
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthenticated')) {
        await _clearLocalData();
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }
      
      rethrow;
    }
  }

  // Enhanced wallet data loading
  Future<void> _loadWalletData() async {
    if (_token == null) return;
    
    debugPrint('💰 Loading wallet data...');
    _hasWalletError = false;
    
    try {
      String endpoint = isAdmin ? '/admin/wallet-overview' : '/user/wallet';
      final walletResponse = await _apiService.getWallet(_token!, endpoint: endpoint);
      
      if (walletResponse['success'] == false) {
        debugPrint('⚠️ Wallet service unavailable, using default values');
        _setDefaultWalletValues();
        _hasWalletError = true;
      } else {
        _wallet = walletResponse;
        debugPrint('✅ Wallet data loaded successfully for ${_user?.roleDisplay}');
      }
      
    } catch (e) {
      debugPrint('❌ Error loading wallet data: $e');
      _setDefaultWalletValues();
      _hasWalletError = true;
    }
  }

  // Token verification
  Future<void> _verifyToken() async {
    if (_token == null) return;
    
    try {
      final response = await _apiService.checkToken(_token!);
      
      if (!response['success']) {
        throw Exception('Token invalid');
      }
      
      // Update abilities from token verification
      final tokenData = response['data']['token'];
      _abilities = List<String>.from(tokenData['abilities'] ?? []);
      
      debugPrint('✅ Token verified successfully');
      
    } catch (e) {
      debugPrint('❌ Token verification failed: $e');
      await _clearLocalData();
      throw Exception('Token tidak valid');
    }
  }

  void _setDefaultWalletValues() {
    _wallet = {
      'balance_rp': 0,
      'balance_koin': 0,
      'data': {
        'balance_rp': 0,
        'balance_koin': 0,
      }
    };
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
      
      if (e.toString().contains('401') || e.toString().contains('Unauthenticated')) {
        _errorMessage = 'Sesi berakhir. Silakan login kembali.';
        await logout();
      } else {
        _errorMessage = 'Gagal memuat data terbaru';
      }
      
      notifyListeners();
    }
  }

  // Public method to refresh wallet data
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

  // UPDATE PROFILE METHOD
  Future<void> updateProfile(Map<String, String> userData) async {
    debugPrint('📝 Updating user profile...');
    _setLoading(true);
    _errorMessage = null;
    
    try {
      if (_token == null) {
        throw Exception('Token tidak tersedia');
      }
      
      String endpoint = isAdmin ? '/admin/profile' : '/user/profile';
      await _apiService.updateProfile(_token!, userData, endpoint: endpoint);
      
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

  // Role-based navigation helper
  String getDefaultRoute() {
    if (isAdmin) {
      return '/admin/dashboard';
    } else if (isUser) {
      return '/user/home';
    }
    return '/login';
  }

  // Check if user can access specific feature
  bool canAccessFeature(String feature) {
    switch (feature) {
      case 'admin_panel':
        return isAdmin;
      case 'user_wallet':
        return isUser || isAdmin;
      case 'scan_qr':
        return isUser;
      case 'manage_users':
        return isAdmin && hasPermission('user:manage');
      case 'manage_dropboxes':
        return isAdmin;
      case 'approve_topups':
        return isAdmin;
      default:
        return isAuthenticated;
    }
  }

  // Get available features based on role
  List<String> getAvailableFeatures() {
    if (isAdmin) {
      return [
        'admin_panel',
        'manage_users',
        'manage_dropboxes',
        'approve_topups',
        'view_statistics',
        'system_monitoring',
      ];
    } else if (isUser) {
      return [
        'user_wallet',
        'scan_qr',
        'transfer_money',
        'exchange_coins',
        'view_history',
        'topup_request',
      ];
    }
    return [];
  }

  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_token != null) {
        await prefs.setString('auth_token', _token!);
      }
      
      if (_user != null) {
        await prefs.setString('user_data', _user!.toJson().toString());
      }
      
      if (_abilities.isNotEmpty) {
        await prefs.setString('user_abilities', _abilities.join(','));
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
      await prefs.remove('user_abilities');
      
      _token = null;
      _user = null;
      _wallet = null;
      _abilities = [];
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String getWalletStatusMessage() {
    if (_hasWalletError) {
      return 'Layanan wallet sedang dalam pengembangan. Beberapa fitur mungkin tidak tersedia.';
    }
    return '';
  }

  bool get isWalletAvailable => !_hasWalletError;

  void debugCurrentState() {
    debugPrint('🔍 AuthProvider state:');
    debugPrint('   isLoggedIn: $isLoggedIn');
    debugPrint('   isAuthenticated: $isAuthenticated');
    debugPrint('   isAdmin: $isAdmin');
    debugPrint('   isUser: $isUser');
    debugPrint('   userRole: $userRole');
    debugPrint('   abilities: $_abilities');
    debugPrint('   isLoading: $isLoading');
    debugPrint('   isInitialized: $isInitialized');
    debugPrint('   hasWalletError: $hasWalletError');
  }
}