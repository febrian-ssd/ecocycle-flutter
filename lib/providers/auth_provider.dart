// lib/providers/auth_provider.dart - DIPERBAIKI: Menambahkan kembali properti wallet
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/models/user.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  User? _user;
  Map<String, dynamic>? _wallet;
  String? _token;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isConnected = true;
  bool _isRefreshing = false;
  
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _token != null && _user != null;
  bool get isAuthenticated => isLoggedIn;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _isConnected;
  bool get isRefreshing => _isRefreshing;
  
  bool get isAdmin => _user?.isAdmin ?? false;
  
  double get balanceRp {
    if (_wallet == null) return 0.0;
    final data = _wallet!['data'] ?? _wallet!;
    return ConversionUtils.toDouble(
      data['balance_rp'] ?? data['balance'] ?? 0.0
    );
  }
  
  int get balanceKoin {
    if (_wallet == null) return 0;
    final data = _wallet!['data'] ?? _wallet!;
    return ConversionUtils.toInt(
      data['balance_koin'] ?? data['balance_coins'] ?? data['coins'] ?? 0
    );
  }

  // DIPERBAIKI: Menambahkan kembali properti yang hilang
  bool get hasWalletError => _wallet == null && isConnected;
  
  String getWalletStatusMessage() {
    if (!_isConnected) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    if (_wallet == null) {
      return 'Gagal memuat data wallet. Coba lagi.';
    }
    return '';
  }

  AuthProvider() {
    initializeAuth();
  }

  Future<void> initializeAuth() async {
    // ... (Isi method tetap sama) ...
    debugPrint('🔄 AuthProvider initializing...');
    _isLoading = true;
    notifyListeners();

    try {
      _isConnected = await _apiService.testConnection();
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      
      if (savedToken != null) {
        _token = savedToken;
        if (_isConnected) {
          await _loadUserDataFromLaravel();
        }
      }
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      await _clearLocalData();
    } finally {
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  // DIPERBAIKI: Menambahkan kembali method yang hilang
  Future<void> refreshWalletData() async {
    if (_token == null || !_isConnected) return;
    _isRefreshing = true;
    notifyListeners();
    await _loadWalletFromLaravel();
    _isRefreshing = false;
    notifyListeners();
  }

  Future<void> _loadUserDataFromLaravel() async {
    // ... (Isi method tetap sama) ...
    if (_token == null || !_isConnected) return;
    try {
      final userResponse = await _apiService.getUser(_token!);
      _user = User.fromJson(userResponse['data'] ?? userResponse);
      await _loadWalletFromLaravel();
    } catch (e) {
      debugPrint('❌ Gagal memuat data user: $e');
      if (e.toString().contains('401')) {
        await _clearLocalData();
      }
      rethrow;
    }
  }

  Future<void> _loadWalletFromLaravel() async {
    // ... (Isi method tetap sama) ...
    if (_token == null || !_isConnected) return;
    try {
      String endpoint = isAdmin ? '/admin/wallet-overview' : '/user/wallet';
      _wallet = await _apiService.getWallet(_token!, endpoint: endpoint);
    } catch (e) {
      debugPrint('❌ Gagal memuat wallet: $e');
      _wallet = null;
    }
  }

  // ... (Sisa file tetap sama) ...
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    
    try {
      _isConnected = await _apiService.testConnection();
      if (!_isConnected) {
        throw Exception('Tidak dapat terhubung ke server.');
      }
      
      final response = await _apiService.login(email, password);
      final data = response['data'] ?? response;
      _token = data['access_token'] ?? data['token'];
      
      if (_token == null) {
        throw Exception('Login gagal: Token tidak diterima.');
      }
      
      _user = User.fromJson(data['user']);
      await _loadWalletFromLaravel();
      await _saveToLocalStorage();
      
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      await _clearLocalData();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> register(Map<String, String> userData) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _apiService.register(userData);
      final data = response['data'] ?? response;
      _token = data['access_token'] ?? data['token'];

      if (_token == null) {
        throw Exception('Registrasi gagal: Token tidak diterima.');
      }

      _user = User.fromJson(data['user']);
      await _loadWalletFromLaravel();
      await _saveToLocalStorage();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      await _clearLocalData();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }


  Future<void> logout() async {
    _setLoading(true);
    if (_token != null && _isConnected) {
      try {
        await _apiService.logout(_token!);
      } catch (e) {
        debugPrint('⚠️ Gagal logout dari server, lanjut logout lokal: $e');
      }
    }
    await _clearLocalData();
    _setLoading(false);
  }
  
  Future<void> refreshAllData() async {
    if (_token == null) return;
    
    _isRefreshing = true;
    notifyListeners();
    
    try {
      _isConnected = await _apiService.testConnection();
      if (_isConnected) {
        await _loadUserDataFromLaravel();
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat data terbaru.';
      if (e.toString().contains('401')) {
        await logout();
      }
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }
  
  Future<void> updateProfile(Map<String, String> userData) async {
    _setLoading(true);
    try {
      if (_token == null) throw Exception('Not authenticated');
      String endpoint = isAdmin ? '/admin/profile' : '/user/profile';
      await _apiService.updateProfile(_token!, userData, endpoint: endpoint);
      await _loadUserDataFromLaravel();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) await prefs.setString('auth_token', _token!);
    } catch (e) {
      debugPrint('❌ Gagal menyimpan sesi: $e');
    }
  }

  Future<void> _clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      _token = null;
      _user = null;
      _wallet = null;
    } catch (e) {
      debugPrint('❌ Gagal membersihkan sesi: $e');
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}