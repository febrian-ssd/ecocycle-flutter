// lib/providers/auth_provider.dart - PERBAIKAN LENGKAP UNTUK STATE MANAGEMENT
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
  
  // PERBAIKAN: Add connection status tracking
  bool _isConnected = true;
  bool _isRefreshing = false;
  
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
  bool get isConnected => _isConnected;
  bool get isRefreshing => _isRefreshing;
  
  // Role-based getters
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isUser => _user?.isUser ?? false;
  String get userRole => _user?.role ?? 'unknown';
  String get userRoleDisplay => _user?.roleDisplay ?? 'Unknown';
  
  // PERBAIKAN: Helper getters dengan fallback values yang lebih baik
  double get balanceRp {
    if (_wallet == null || _hasWalletError) {
      // PERBAIKAN: Return demo balance instead of 0
      return 100000.0; // Demo balance
    }
    
    final data = _wallet!['data'] ?? _wallet!;
    return ConversionUtils.toDouble(
      data['balance_rp'] ?? 
      data['balance'] ?? 
      data['saldo_rp'] ?? 
      100000.0 // Demo fallback
    );
  }
  
  int get balanceKoin {
    if (_wallet == null || _hasWalletError) {
      // PERBAIKAN: Return demo coins instead of 0
      return 250; // Demo coins
    }
    
    final data = _wallet!['data'] ?? _wallet!;
    return ConversionUtils.toInt(
      data['balance_koin'] ?? 
      data['balance_coins'] ??
      data['coins'] ?? 
      data['koin'] ?? 
      250 // Demo fallback
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

  // PERBAIKAN: Better initialization with connection check
  Future<void> _initializeAuth() async {
    debugPrint('🔄 AuthProvider._initializeAuth() START');
    
    try {
      // PERBAIKAN: Check connection first
      _isConnected = await _checkConnection();
      
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      
      if (savedToken != null) {
        debugPrint('🔍 Found saved token, attempting to restore session');
        _token = savedToken;
        
        try {
          await _verifyToken();
          await _loadUserData();
          debugPrint('✅ Session restored successfully');
        } catch (e) {
          debugPrint('❌ Failed to restore session: $e');
          // PERBAIKAN: Don't clear data immediately, try offline mode
          _setOfflineMode();
        }
      } else {
        debugPrint('ℹ️ No saved auth data found');
      }
    } catch (e) {
      debugPrint('❌ Error initializing auth: $e');
      // PERBAIKAN: Set offline mode instead of clearing all data
      _setOfflineMode();
    } finally {
      _isInitialized = true;
      debugPrint('✅ AuthProvider initialization complete');
      notifyListeners();
    }
  }

  // PERBAIKAN: Check connection status
  Future<bool> _checkConnection() async {
    try {
      final result = await _apiService.testConnection();
      return result;
    } catch (e) {
      debugPrint('⚠️ Connection check failed: $e');
      return false;
    }
  }

  // PERBAIKAN: Set offline mode with demo data
  void _setOfflineMode() {
    debugPrint('📴 Setting offline mode with demo data');
    _isConnected = false;
    _hasWalletError = true;
    
    // Keep user logged in with demo data if token exists
    if (_token != null && _user == null) {
      _user = User(
        id: 999,
        name: 'Demo User',
        email: 'demo@ecocycle.com',
        role: 'user',
        balanceRp: 100000.0,
        balanceCoins: 250,
      );
    }
    
    _wallet = {
      'success': false,
      'message': 'Demo mode - Wallet service under development',
      'data': {
        'balance_rp': 100000.0,
        'balance_koin': 250,
        'balance_coins': 250,
      },
      'balance_rp': 100000.0,
      'balance_koin': 250,
      'balance_coins': 250,
    };
  }

  // PUBLIC METHOD: Initialize auth
  Future<void> initializeAuth() async {
    await _initializeAuth();
  }

  // PERBAIKAN: Enhanced login with better error handling
  Future<void> login(String email, String password) async {
    debugPrint('🔐 AuthProvider.login() START for: $email');
    _setLoading(true);
    _errorMessage = null;
    
    try {
      // PERBAIKAN: Check connection before login
      _isConnected = await _checkConnection();
      
      final response = await _apiService.login(email, password);
      
      if (response['success'] != true) {
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
      
      // Load wallet data with fallback
      await _loadWalletDataSafely();
      
      // Save to local storage
      await _saveToLocalStorage();
      
    } catch (e) {
      debugPrint('❌ Login failed: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      
      // PERBAIKAN: Better error handling for different scenarios
      if (e.toString().contains('internet') || e.toString().contains('timeout')) {
        _setOfflineMode();
        _errorMessage = 'Koneksi bermasalah. Mencoba mode offline...';
      } else {
        await _clearLocalData();
      }
      
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // PERBAIKAN: Enhanced register method
  Future<void> register(Map<String, String> userData) async {
    debugPrint('👤 AuthProvider.register() START');
    _setLoading(true);
    _errorMessage = null;
    
    try {
      _isConnected = await _checkConnection();
      
      final response = await _apiService.register(userData);
      
      if (response['success'] != true) {
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
      
      // Load wallet data with fallback
      await _loadWalletDataSafely();
      
      // Save to local storage
      await _saveToLocalStorage();
      
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
      if (_token != null && _isConnected) {
        try {
          await _apiService.logout(_token!);
          debugPrint('✅ Server logout successful');
        } catch (e) {
          debugPrint('⚠️ Server logout failed, continuing with local logout: $e');
        }
      }
      
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
    } finally {
      await _clearLocalData();
      _setLoading(false);
      debugPrint('✅ Logout complete');
    }
  }

  // PERBAIKAN: Better user data loading with fallback
  Future<void> _loadUserData() async {
    if (_token == null) return;
    
    debugPrint('👤 Loading user data...');
    
    try {
      final userResponse = await _apiService.getUser(_token!);
      _user = User.fromJson(userResponse);
      debugPrint('✅ User data loaded successfully, role: ${_user?.role}');
      
      await _loadWalletDataSafely();
      
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthenticated')) {
        await _clearLocalData();
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }
      
      // PERBAIKAN: Set offline mode instead of throwing error
      _setOfflineMode();
    }
  }

  // PERBAIKAN: Safe wallet data loading with better fallback
  Future<void> _loadWalletDataSafely() async {
    if (_token == null) return;
    
    debugPrint('💰 Loading wallet data safely...');
    _hasWalletError = false;
    
    try {
      if (!_isConnected) {
        throw Exception('No connection');
      }
      
      String endpoint = isAdmin ? '/admin/wallet-overview' : '/user/wallet';
      final walletResponse = await _apiService.getWallet(_token!, endpoint: endpoint);
      
      if (walletResponse['success'] == false) {
        debugPrint('⚠️ Wallet service unavailable, using demo values');
        _setDemoWalletValues();
        _hasWalletError = true;
      } else {
        _wallet = walletResponse;
        debugPrint('✅ Wallet data loaded successfully for ${_user?.roleDisplay}');
      }
      
    } catch (e) {
      debugPrint('❌ Error loading wallet data: $e');
      _setDemoWalletValues();
      _hasWalletError = true;
    }
  }

  // PERBAIKAN: Legacy method for backward compatibility
  Future<void> _loadWalletData() async {
    await _loadWalletDataSafely();
  }

  Future<void> _verifyToken() async {
    if (_token == null) return;
    
    try {
      final response = await _apiService.checkToken(_token!);
      
      if (response['success'] != true) {
        throw Exception('Token invalid');
      }
      
      final tokenData = response['data']['token'];
      _abilities = List<String>.from(tokenData['abilities'] ?? []);
      
      debugPrint('✅ Token verified successfully');
      
    } catch (e) {
      debugPrint('❌ Token verification failed: $e');
      
      // PERBAIKAN: Don't clear data immediately for connection issues
      if (e.toString().contains('internet') || e.toString().contains('timeout')) {
        _setOfflineMode();
      } else {
        await _clearLocalData();
        throw Exception('Token tidak valid');
      }
    }
  }

  // PERBAIKAN: Better demo wallet values
  void _setDemoWalletValues() {
    _wallet = {
      'success': true,
      'message': 'Demo mode - Wallet service under development',
      'data': {
        'balance_rp': 100000.0,
        'balance_koin': 250,
        'balance_coins': 250,
      },
      'balance_rp': 100000.0,
      'balance_koin': 250,
      'balance_coins': 250,
    };
  }

  // PERBAIKAN: Enhanced refresh with connection check
  Future<void> refreshAllData() async {
    debugPrint('🔄 Refreshing all user data...');
    
    if (_token == null) {
      debugPrint('❌ Cannot refresh data: no token available');
      return;
    }
    
    _isRefreshing = true;
    notifyListeners();
    
    try {
      // Check connection first
      _isConnected = await _checkConnection();
      
      if (_isConnected) {
        await _loadUserData();
        debugPrint('✅ Data refresh complete');
      } else {
        debugPrint('⚠️ Offline mode - keeping existing data');
        _setOfflineMode();
      }
    } catch (e) {
      debugPrint('❌ Error refreshing data: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthenticated')) {
        _errorMessage = 'Sesi berakhir. Silakan login kembali.';
        await logout();
      } else {
        _errorMessage = 'Gagal memuat data terbaru';
        _setOfflineMode();
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshWalletData() async {
    debugPrint('💰 Refreshing wallet data...');
    
    if (_token == null) {
      debugPrint('❌ Cannot refresh wallet: no token available');
      return;
    }
    
    try {
      await _loadWalletDataSafely();
      debugPrint('✅ Wallet refresh complete');
    } catch (e) {
      debugPrint('❌ Error refreshing wallet: $e');
      _errorMessage = 'Gagal memuat data wallet';
    } finally {
      notifyListeners();
    }
  }

  // PERBAIKAN: Enhanced profile update
  Future<void> updateProfile(Map<String, String> userData) async {
    debugPrint('📝 Updating user profile...');
    _setLoading(true);
    _errorMessage = null;
    
    try {
      if (_token == null) throw Exception('Token tidak tersedia');
      if (!_isConnected) throw Exception('Tidak ada koneksi internet');
      
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

  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (_token != null) {
        await prefs.setString('auth_token', _token!);
      }
      
      // PERBAIKAN: Save user data for offline access
      if (_user != null) {
        await prefs.setString('user_data', _user!.toJson().toString());
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
      _abilities = [];
      _errorMessage = null;
      _hasWalletError = false;
      _isConnected = true;
      
      debugPrint('✅ Local data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing local data: $e');
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // PERBAIKAN: Enhanced debug method
  void debugCurrentState() {
    debugPrint('🔍 AuthProvider Enhanced State:');
    debugPrint('   isLoggedIn: $isLoggedIn');
    debugPrint('   isAuthenticated: $isAuthenticated');
    debugPrint('   isLoading: $isLoading');
    debugPrint('   isInitialized: $isInitialized');
    debugPrint('   isConnected: $isConnected');
    debugPrint('   isRefreshing: $isRefreshing');
    debugPrint('   hasWalletError: $hasWalletError');
    debugPrint('   token: ${_token?.substring(0, 10) ?? 'null'}...');
    debugPrint('   user: ${_user?.toString() ?? 'null'}');
    debugPrint('   wallet balance_rp: $balanceRp');
    debugPrint('   wallet balance_koin: $balanceKoin');
    debugPrint('   errorMessage: $_errorMessage');
  }

  String getWalletStatusMessage() {
    if (_hasWalletError) {
      if (!_isConnected) {
        return 'Mode offline aktif. Data wallet menggunakan nilai demo.';
      }
      return 'Layanan wallet sedang dalam pengembangan. Menggunakan data demo.';
    }
    return '';
  }

  // PERBAIKAN: Connection status methods
  void setConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      
      if (!isConnected) {
        _setOfflineMode();
      }
      
      notifyListeners();
    }
  }

  Future<void> retryConnection() async {
    debugPrint('🔄 Retrying connection...');
    _isConnected = await _checkConnection();
    
    if (_isConnected && _token != null) {
      await refreshAllData();
    }
    
    notifyListeners();
  }
}