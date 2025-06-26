// lib/providers/auth_provider.dart - RESTORED LARAVEL CONNECTIVITY
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
  
  // Laravel connection status
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
  bool get isConnected => _isConnected;
  bool get isRefreshing => _isRefreshing;
  
  // Role-based getters
  bool get isAdmin => _user?.isAdmin ?? false;
  bool get isUser => _user?.isUser ?? false;
  String get userRole => _user?.role ?? 'unknown';
  String get userRoleDisplay => _user?.roleDisplay ?? 'Unknown';
  
  // Balance getters - directly from Laravel
  double get balanceRp {
    if (_wallet == null) return 0.0;
    
    final data = _wallet!['data'] ?? _wallet!;
    return ConversionUtils.toDouble(
      data['balance_rp'] ?? 
      data['balance'] ?? 
      data['saldo_rp'] ?? 
      0.0
    );
  }
  
  int get balanceKoin {
    if (_wallet == null) return 0;
    
    final data = _wallet!['data'] ?? _wallet!;
    return ConversionUtils.toInt(
      data['balance_koin'] ?? 
      data['balance_coins'] ??
      data['coins'] ?? 
      data['koin'] ?? 
      0
    );
  }

  // Laravel connection status
  bool get hasWalletError => !_isConnected;

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
    debugPrint('🔄 AuthProvider initializing for Laravel...');
    
    try {
      _isConnected = await _apiService.testConnection();
      debugPrint('🔍 Laravel connection status: $_isConnected');
      
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      
      if (savedToken != null) {
        debugPrint('🔍 Found saved token, restoring Laravel session');
        _token = savedToken;
        
        if (_isConnected) {
          try {
            await _verifyTokenWithLaravel();
            await _loadUserDataFromLaravel();
            debugPrint('✅ Laravel session restored successfully');
          } catch (e) {
            debugPrint('❌ Laravel session restore failed: $e');
            await _clearLocalData();
          }
        } else {
          debugPrint('📴 Laravel offline, clearing session');
          await _clearLocalData();
        }
      } else {
        debugPrint('ℹ️ No saved Laravel session found');
      }
    } catch (e) {
      debugPrint('❌ Laravel initialization error: $e');
      _isConnected = false;
    } finally {
      _isInitialized = true;
      debugPrint('✅ Laravel AuthProvider initialization complete');
      notifyListeners();
    }
  }

  Future<void> initializeAuth() async {
    await _initializeAuth();
  }

  Future<void> login(String email, String password) async {
    debugPrint('🔐 Laravel login START for: $email');
    _setLoading(true);
    _errorMessage = null;
    
    try {
      _isConnected = await _apiService.testConnection();
      if (!_isConnected) {
        throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      }
      
      final response = await _apiService.login(email, password);
      
      if (response['success'] != true && response['data'] == null) {
        throw Exception(response['message'] ?? 'Login gagal');
      }
      
      final data = response['data'] ?? response;
      _token = data['access_token'] ?? data['token'];
      _abilities = List<String>.from(data['abilities'] ?? []);
      
      if (_token == null) {
        throw Exception('Token tidak ditemukan dalam respons server');
      }
      
      final userData = data['user'];
      _user = User.fromJson(userData);
      
      debugPrint('✅ Laravel login successful, role: ${_user?.role}');
      
      await _loadWalletFromLaravel();
      await _saveToLocalStorage();
      
    } catch (e) {
      debugPrint('❌ Laravel login failed: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      await _clearLocalData();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(Map<String, String> userData) async {
    debugPrint('👤 Laravel register START');
    _setLoading(true);
    _errorMessage = null;
    
    try {
      _isConnected = await _apiService.testConnection();
      if (!_isConnected) {
        throw Exception('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
      }
      
      final response = await _apiService.register(userData);
      
      if (response['success'] != true && response['data'] == null) {
        throw Exception(response['message'] ?? 'Registrasi gagal');
      }
      
      final data = response['data'] ?? response;
      _token = data['access_token'] ?? data['token'];
      _abilities = List<String>.from(data['abilities'] ?? []);
      
      if (_token == null) {
        throw Exception('Token tidak ditemukan dalam respons server');
      }
      
      final userDataResponse = data['user'];
      _user = User.fromJson(userDataResponse);
      
      debugPrint('✅ Laravel registration successful, role: ${_user?.role}');
      
      await _loadWalletFromLaravel();
      await _saveToLocalStorage();
      
    } catch (e) {
      debugPrint('❌ Laravel registration failed: $e');
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      await _clearLocalData();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    debugPrint('🔄 Laravel logout START');
    _setLoading(true);
    
    try {
      if (_token != null && _isConnected) {
        try {
          await _apiService.logout(_token!);
          debugPrint('✅ Laravel logout successful');
        } catch (e) {
          debugPrint('⚠️ Laravel logout failed, continuing with local logout: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Error during Laravel logout: $e');
    } finally {
      await _clearLocalData();
      _setLoading(false);
      debugPrint('✅ Laravel logout complete');
    }
  }

  Future<void> _loadUserDataFromLaravel() async {
    if (_token == null || !_isConnected) return;
    
    debugPrint('👤 Loading user data from Laravel...');
    
    try {
      final userResponse = await _apiService.getUser(_token!);
      final userData = userResponse['data'] ?? userResponse;
      _user = User.fromJson(userData);
      debugPrint('✅ Laravel user data loaded, role: ${_user?.role}');
      
      await _loadWalletFromLaravel();
      
    } catch (e) {
      debugPrint('❌ Error loading Laravel user data: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthenticated')) {
        await _clearLocalData();
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }
      rethrow;
    }
  }

  Future<void> _loadWalletFromLaravel() async {
    if (_token == null || !_isConnected) return;
    
    debugPrint('💰 Loading wallet from Laravel...');
    
    try {
      String endpoint = isAdmin ? '/admin/wallet-overview' : '/user/wallet';
      final walletResponse = await _apiService.getWallet(_token!, endpoint: endpoint);
      
      _wallet = walletResponse;
      debugPrint('✅ Laravel wallet loaded for ${_user?.roleDisplay}');
      
    } catch (e) {
      debugPrint('❌ Error loading Laravel wallet: $e');
      // Don't throw error for wallet - just log it
      _wallet = {
        'data': {
          'balance_rp': 0.0,
          'balance_coins': 0,
        }
      };
    }
  }

  Future<void> _verifyTokenWithLaravel() async {
    if (_token == null || !_isConnected) return;
    
    try {
      final response = await _apiService.checkToken(_token!);
      
      if (response['success'] != true && response['data'] == null) {
        throw Exception('Token invalid');
      }
      
      // Laravel might return abilities in different format
      final userData = response['data'] ?? response;
      if (userData['abilities'] != null) {
        _abilities = List<String>.from(userData['abilities']);
      }
      
      debugPrint('✅ Laravel token verified successfully');
      
    } catch (e) {
      debugPrint('❌ Laravel token verification failed: $e');
      await _clearLocalData();
      throw Exception('Token tidak valid');
    }
  }

  Future<void> refreshAllData() async {
    debugPrint('🔄 Refreshing all Laravel data...');
    
    if (_token == null) {
      debugPrint('❌ Cannot refresh data: no token available');
      return;
    }
    
    _isRefreshing = true;
    notifyListeners();
    
    try {
      _isConnected = await _apiService.testConnection();
      
      if (_isConnected) {
        await _loadUserDataFromLaravel();
        debugPrint('✅ Laravel data refresh complete');
      } else {
        debugPrint('⚠️ Laravel offline - keeping existing data');
        _isConnected = false;
      }
    } catch (e) {
      debugPrint('❌ Error refreshing Laravel data: $e');
      
      if (e.toString().contains('401') || e.toString().contains('Unauthenticated')) {
        _errorMessage = 'Sesi berakhir. Silakan login kembali.';
        await logout();
      } else {
        _errorMessage = 'Gagal memuat data terbaru';
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshWalletData() async {
    debugPrint('💰 Refreshing Laravel wallet data...');
    
    if (_token == null) {
      debugPrint('❌ Cannot refresh wallet: no token available');
      return;
    }
    
    try {
      await _loadWalletFromLaravel();
      debugPrint('✅ Laravel wallet refresh complete');
    } catch (e) {
      debugPrint('❌ Error refreshing Laravel wallet: $e');
      _errorMessage = 'Gagal memuat data wallet';
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, String> userData) async {
    debugPrint('📝 Updating profile in Laravel...');
    _setLoading(true);
    _errorMessage = null;
    
    try {
      if (_token == null) throw Exception('Token tidak tersedia');
      if (!_isConnected) throw Exception('Tidak ada koneksi internet');
      
      String endpoint = isAdmin ? '/admin/profile' : '/user/profile';
      await _apiService.updateProfile(_token!, userData, endpoint: endpoint);
      
      await _loadUserDataFromLaravel();
      
      debugPrint('✅ Laravel profile updated successfully');
      
    } catch (e) {
      debugPrint('❌ Laravel profile update failed: $e');
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
      
      if (_user != null) {
        await prefs.setString('user_data', _user!.toJson().toString());
      }
      
      debugPrint('✅ Laravel session saved to local storage');
    } catch (e) {
      debugPrint('❌ Error saving Laravel session: $e');
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
      _isConnected = true;
      
      debugPrint('✅ Laravel session cleared');
    } catch (e) {
      debugPrint('❌ Error clearing Laravel session: $e');
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void debugCurrentState() {
    debugPrint('🔍 Laravel AuthProvider State:');
    debugPrint('   isLoggedIn: $isLoggedIn');
    debugPrint('   isAuthenticated: $isAuthenticated');
    debugPrint('   isLoading: $isLoading');
    debugPrint('   isInitialized: $isInitialized');
    debugPrint('   isConnected: $isConnected');
    debugPrint('   isRefreshing: $isRefreshing');
    debugPrint('   token: ${_token?.substring(0, 10) ?? 'null'}...');
    debugPrint('   user: ${_user?.toString() ?? 'null'}');
    debugPrint('   wallet balance_rp: $balanceRp');
    debugPrint('   wallet balance_koin: $balanceKoin');
    debugPrint('   errorMessage: $_errorMessage');
  }

  String getWalletStatusMessage() {
    if (!_isConnected) {
      return 'Tidak dapat terhubung ke server Laravel. Periksa koneksi internet.';
    }
    return '';
  }

  void setConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      notifyListeners();
    }
  }

  Future<void> retryConnection() async {
    debugPrint('🔄 Retrying Laravel connection...');
    _isConnected = await _apiService.testConnection();
    
    if (_isConnected && _token != null) {
      await refreshAllData();
    }
    
    notifyListeners();
  }
}