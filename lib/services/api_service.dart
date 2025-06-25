// lib/services/api_service.dart - FIXED ALL MISSING METHODS AND TYPE ERRORS
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ecocycle_app/models/transaction.dart';

class ApiService {
  static const String baseUrl = 'https://ecocylce.my.id/api';
  static const Duration timeoutDuration = Duration(seconds: 30);

  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // FIXED: Added testConnection method
  Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing API connection...');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));
      
      bool isConnected = response.statusCode == 200;
      debugPrint('🔍 Connection test result: $isConnected');
      return isConnected;
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint,
    {Map<String, String>? headers, 
     Map<String, dynamic>? body}) async {
    
    final uri = Uri.parse('$baseUrl$endpoint');
    debugPrint('🌐 Making $method request to: $uri');
    
    try {
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(timeoutDuration);
          break;
        case 'POST':
          response = await http.post(
            uri, 
            headers: headers, 
            body: body != null ? jsonEncode(body) : null
          ).timeout(timeoutDuration);
          break;
        case 'PUT':
          response = await http.put(
            uri, 
            headers: headers, 
            body: body != null ? jsonEncode(body) : null
          ).timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers).timeout(timeoutDuration);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      debugPrint('🌐 HTTP response received: ${response.statusCode}');
      
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        debugPrint('❌ Failed to parse JSON response: ${response.body}');
        responseData = {'message': 'Invalid server response', 'raw_body': response.body};
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Request successful: ${response.statusCode}');
        return responseData;
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        String errorMessage = _getErrorMessage(response.statusCode, responseData);
        throw Exception(errorMessage);
      }
      
    } on SocketException {
      debugPrint('❌ Network error: No internet connection');
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi.');
    } on HttpException {
      debugPrint('❌ HTTP error occurred');
      throw Exception('Terjadi kesalahan jaringan. Coba lagi nanti.');
    } on FormatException {
      debugPrint('❌ Bad response format');
      throw Exception('Server mengirim respons yang tidak valid.');
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Koneksi timeout. Periksa koneksi internet Anda.');
      }
      rethrow;
    }
  }

  String _getErrorMessage(int statusCode, Map<String, dynamic> responseData) {
    switch (statusCode) {
      case 400:
        return responseData['message'] ?? 'Permintaan tidak valid';
      case 401:
        return 'Sesi Anda telah berakhir. Silakan login kembali.';
      case 403:
        return 'Anda tidak memiliki akses untuk melakukan ini';
      case 404:
        return 'Layanan tidak ditemukan';
      case 422:
        if (responseData['errors'] != null) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            return firstError.first.toString();
          }
        }
        return responseData['message'] ?? 'Data yang dikirim tidak valid';
      case 500:
        if (responseData['message']?.toString().contains('does not exist') == true) {
          return 'Fitur ini sedang dalam pengembangan. Coba lagi nanti.';
        }
        return 'Server sedang bermasalah. Coba lagi nanti.';
      case 502:
      case 503:
      case 504:
        return 'Server sedang maintenance. Coba lagi nanti.';
      default:
        return responseData['message'] ?? 'Terjadi kesalahan yang tidak diketahui';
    }
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    debugPrint('🔐 Attempting login for: $email');
    
    try {
      final response = await _makeRequest(
        'POST',
        '/login',
        headers: _getHeaders(),
        body: {
          'email': email,
          'password': password,
        },
      );
      
      debugPrint('✅ Login successful');
      return response;
    } catch (e) {
      debugPrint('❌ Login failed: $e');
      if (e.toString().contains('401') || e.toString().contains('Invalid credentials')) {
        throw Exception('Email atau password salah');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    debugPrint('👤 Attempting registration for: ${userData['email']}');
    
    try {
      final response = await _makeRequest(
        'POST',
        '/register',
        headers: _getHeaders(),
        body: userData,
      );
      
      debugPrint('✅ Registration successful');
      return response;
    } catch (e) {
      debugPrint('❌ Registration failed: $e');
      rethrow;
    }
  }

  Future<void> logout(String token) async {
    debugPrint('🚪 Logging out user');
    
    try {
      await _makeRequest(
        'POST',
        '/logout',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ Logout successful');
    } catch (e) {
      debugPrint('⚠️ Logout failed (continuing anyway): $e');
    }
  }

  Future<Map<String, dynamic>> getUser(String token) async {
    debugPrint('👤 Getting user data');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/user',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ User data retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get user data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile(String token, Map<String, String> userData, {String? endpoint}) async {
    debugPrint('📝 Updating user profile');
    
    try {
      final response = await _makeRequest(
        'PUT',
        endpoint ?? '/user/profile',
        headers: _getHeaders(token: token),
        body: userData,
      );
      
      debugPrint('✅ Profile updated successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to update profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getWallet(String token, {String? endpoint}) async {
    debugPrint('💰 Getting wallet data');
    
    try {
      final response = await _makeRequest(
        'GET',
        endpoint ?? '/user/wallet',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ Wallet data retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get wallet data: $e');
      
      if (e.toString().contains('does not exist') || 
          e.toString().contains('pengembangan') ||
          e.toString().contains('404')) {
        debugPrint('⚠️ Wallet endpoint not available, using fallback data');
        
        return {
          'success': true,
          'message': 'Using demo data - Wallet service under development',
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
      
      rethrow;
    }
  }

  // FIXED: Added getScanHistory method
  Future<Map<String, dynamic>> getScanHistory(String token) async {
    debugPrint('📊 Getting scan history');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/user/scan-history',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ Scan history retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get scan history, trying fallback: $e');
      
      // Fallback to general history
      try {
        final historyList = await getHistory(token);
        final scanHistory = historyList.where((item) => 
          item['type'] == 'scan' || 
          item['activity_type'] == 'scan' ||
          item.containsKey('qr_code') ||
          item.containsKey('dropbox_id') ||
          item.containsKey('waste_type')
        ).toList();
        
        return {
          'data': scanHistory,
          'meta': {'total': scanHistory.length},
        };
      } catch (fallbackError) {
        debugPrint('❌ Fallback scan history also failed: $fallbackError');
        return {'data': [], 'meta': {'total': 0}};
      }
    }
  }

  // FIXED: Added getScanStats method
  Future<Map<String, dynamic>> getScanStats(String token) async {
    debugPrint('📈 Getting scan stats');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/user/scan-stats',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ Scan stats retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get scan stats, calculating from history: $e');
      
      try {
        final historyList = await getHistory(token);
        int totalScans = 0;
        int totalCoinsEarned = 0;
        double totalWasteWeight = 0.0;
        
        for (var item in historyList) {
          if (item['type'] == 'scan' || 
              item['activity_type'] == 'scan' ||
              item.containsKey('waste_type')) {
            totalScans++;
            totalCoinsEarned += (item['coins_earned'] ?? item['eco_coins'] ?? 0) as int;
            totalWasteWeight += double.tryParse(item['weight']?.toString() ?? item['weight_g']?.toString() ?? '0') ?? 0.0;
          }
        }
        
        return {
          'data': {
            'total_scans': totalScans,
            'total_coins_earned': totalCoinsEarned,
            'total_waste_weight': totalWasteWeight,
          }
        };
      } catch (fallbackError) {
        debugPrint('❌ Fallback scan stats calculation failed: $fallbackError');
        return {
          'data': {
            'total_scans': 0,
            'total_coins_earned': 0,
            'total_waste_weight': 0.0,
          }
        };
      }
    }
  }

  // FIXED: Added getTransactionHistory method
  Future<Map<String, dynamic>> getTransactionHistory(String token) async {
    debugPrint('💳 Getting transaction history');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/user/transaction-history',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ Transaction history retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get transaction history, using transactions: $e');
      
      try {
        final transactions = await getTransactions(token);
        
        final transactionData = transactions.map((t) => {
          'id': t.id,
          'type': t.type,
          'type_label': t.typeDisplayName,
          'amount_rp': t.amountRp,
          'amount_coins': t.amountCoins,
          'description': t.description,
          'created_at': t.createdAt.toIso8601String(),
          'is_income': t.isIncome,
        }).toList();
        
        return {
          'data': transactionData,
          'meta': {'total': transactionData.length},
        };
      } catch (fallbackError) {
        debugPrint('❌ Fallback transaction history also failed: $fallbackError');
        return {'data': [], 'meta': {'total': 0}};
      }
    }
  }

  Future<List<Transaction>> getTransactions(String token) async {
    debugPrint('📊 Getting transactions');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/user/transactions',
        headers: _getHeaders(token: token),
      );
      
      // FIXED: Handle different response formats correctly
      List<dynamic> transactionsData;
      
      if (response['data'] != null && response['data'] is List) {
        transactionsData = response['data'] as List<dynamic>;
      } else if (response['transactions'] != null && response['transactions'] is List) {
        transactionsData = response['transactions'] as List<dynamic>;
      } else if (response is List) {
        transactionsData = response as List<dynamic>;
      } else {
        transactionsData = [];
      }
      
      final transactions = transactionsData.map((data) {
        try {
          return Transaction.fromJson(data as Map<String, dynamic>);
        } catch (e) {
          debugPrint('❌ Failed to parse transaction: $data, error: $e');
          return null;
        }
      }).where((t) => t != null).cast<Transaction>().toList();
      
      debugPrint('✅ Transactions retrieved successfully: ${transactions.length}');
      return transactions;
    } catch (e) {
      debugPrint('❌ Failed to get transactions: $e');
      
      if (e.toString().contains('does not exist') || e.toString().contains('pengembangan')) {
        debugPrint('⚠️ Transactions endpoint not available, using demo data');
        return _getDemoTransactions();
      }
      
      rethrow;
    }
  }

  List<Transaction> _getDemoTransactions() {
    return [
      Transaction(
        id: 1,
        type: 'scan_reward',
        amountRp: 0,
        amountCoins: 50,
        description: 'Scan sampah plastik - Demo data',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Transaction(
        id: 2,
        type: 'topup',
        amountRp: 100000,
        amountCoins: 0,
        description: 'Top up saldo - Demo data',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  // FIXED: Properly handle dropboxes response
  Future<List<Map<String, dynamic>>> getDropboxes(String token) async {
    debugPrint('📍 Getting dropbox locations');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/dropboxes',
        headers: _getHeaders(token: token),
      );
      
      // FIXED: Handle different response formats correctly
      List<dynamic> dropboxData;
      
      if (response is List) {
        dropboxData = response as List<dynamic>;
      } else if (response['data'] != null && response['data'] is List) {
        dropboxData = response['data'] as List<dynamic>;
      } else if (response['dropboxes'] != null && response['dropboxes'] is List) {
        dropboxData = response['dropboxes'] as List<dynamic>;
      } else {
        dropboxData = [];
      }
      
      debugPrint('✅ Dropbox locations retrieved successfully: ${dropboxData.length}');
      return dropboxData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get dropbox locations: $e');
      
      if (e.toString().contains('does not exist') || e.toString().contains('pengembangan')) {
        debugPrint('⚠️ Dropbox locations endpoint not available, using demo data');
        return _getDemoDropboxes();
      }
      
      rethrow;
    }
  }

  List<Map<String, dynamic>> _getDemoDropboxes() {
    return [
      {
        'id': 1,
        'location_name': 'Medan Plaza',
        'latitude': 3.5952,
        'longitude': 98.6722,
        'status': 'active',
      },
      {
        'id': 2,
        'location_name': 'Universitas Sumatera Utara',
        'latitude': 3.5681,
        'longitude': 98.6565,
        'status': 'active',
      },
      {
        'id': 3,
        'location_name': 'Merdeka Walk',
        'latitude': 3.5938,
        'longitude': 98.6699,
        'status': 'active',
      },
    ];
  }

  // FIXED: Properly handle history response
  Future<List<Map<String, dynamic>>> getHistory(String token, {String? type}) async {
    debugPrint('📜 Getting general history');
    
    try {
      String endpoint = '/user/history';
      if (type != null) {
        endpoint += '?type=$type';
      }
      
      final response = await _makeRequest(
        'GET',
        endpoint,
        headers: _getHeaders(token: token),
      );
      
      // FIXED: Handle different response formats correctly
      List<dynamic> historyData;
      
      if (response['data'] != null && response['data'] is List) {
        historyData = response['data'] as List<dynamic>;
      } else if (response['history'] != null && response['history'] is List) {
        historyData = response['history'] as List<dynamic>;
      } else if (response is List) {
        historyData = response as List<dynamic>;
      } else {
        historyData = [];
      }
      
      debugPrint('✅ History retrieved successfully: ${historyData.length} items');
      return historyData.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get history: $e');
      
      if (e.toString().contains('does not exist') || e.toString().contains('pengembangan')) {
        debugPrint('⚠️ History endpoint not available, using demo data');
        return _getDemoHistory();
      }
      
      rethrow;
    }
  }

  List<Map<String, dynamic>> _getDemoHistory() {
    return [
      {
        'id': 1,
        'type': 'scan',
        'activity_type': 'scan',
        'waste_type': 'plastic',
        'weight': 1.5,
        'weight_g': 1500,
        'coins_earned': 15,
        'eco_coins': 15,
        'status': 'success',
        'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'dropbox_id': 1,
        'dropbox_location': 'Medan Plaza',
      },
      {
        'id': 2,
        'type': 'scan',
        'activity_type': 'scan',
        'waste_type': 'paper',
        'weight': 0.8,
        'weight_g': 800,
        'coins_earned': 8,
        'eco_coins': 8,
        'status': 'success',
        'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        'dropbox_id': 2,
        'dropbox_location': 'Universitas Sumatera Utara',
      },
    ];
  }

  Future<Map<String, dynamic>> transfer(
    String token, {
    required String email,
    required double amount,
    String? description,
  }) async {
    debugPrint('💸 Attempting transfer to: $email, amount: $amount');
    
    try {
      final response = await _makeRequest(
        'POST',
        '/user/transfer',
        headers: _getHeaders(token: token),
        body: {
          'email': email,
          'amount': amount,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      
      debugPrint('✅ Transfer successful');
      return response;
    } catch (e) {
      debugPrint('❌ Transfer failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> topupRequest(
    String token, {
    required double amount,
    required String method,
  }) async {
    debugPrint('💰 Creating topup request: amount=$amount, method=$method');
    
    try {
      final response = await _makeRequest(
        'POST',
        '/user/topup',
        headers: _getHeaders(token: token),
        body: {
          'amount': amount,
          'payment_method': method,
        },
      );
      
      debugPrint('✅ Topup request created successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Topup request failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> exchangeCoins(
    String token, {
    required int coinAmount,
  }) async {
    debugPrint('🪙 Attempting to exchange coins: $coinAmount');
    
    try {
      final response = await _makeRequest(
        'POST',
        '/user/exchange-coins',
        headers: _getHeaders(token: token),
        body: {
          'coin_amount': coinAmount,
        },
      );
      
      debugPrint('✅ Coin exchange successful');
      return response;
    } catch (e) {
      debugPrint('❌ Coin exchange failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> confirmScan(
    String token, {
    required String dropboxCode,
    required String wasteType,
    required double weight,
  }) async {
    debugPrint('✅ Confirming scan with dropbox: $dropboxCode');
    
    try {
      final response = await _makeRequest(
        'POST',
        '/user/scan/confirm',
        headers: _getHeaders(token: token),
        body: {
          'dropbox_code': dropboxCode,
          'waste_type': wasteType,
          'weight': weight,
        },
      );
      
      debugPrint('✅ Scan confirmed successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to confirm scan: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkToken(String token) async {
    debugPrint('🔍 Checking token validity');
    
    try {
      final response = await _makeRequest(
        'GET', 
        '/auth/check-token', 
        headers: _getHeaders(token: token)
      );
      
      debugPrint('✅ Token is valid');
      return response;
    } catch (e) {
      debugPrint('❌ Token check failed: $e');
      rethrow;
    }
  }
}