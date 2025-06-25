// lib/services/api_service.dart - COMPLETE FIXED VERSION
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ecocycle_app/models/transaction.dart';

class ApiService {
  static const String baseUrl = 'https://ecocylce.my.id/api';
  static const Duration timeoutDuration = Duration(seconds: 30);

  // Helper method to create headers
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

  // Enhanced HTTP request wrapper with better error handling
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint,
    {Map<String, String>? headers, 
     Map<String, dynamic>? body,
     bool expectSuccess = true}) async {
    
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
      
      // Try to parse response body
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        debugPrint('❌ Failed to parse JSON response: ${response.body}');
        responseData = {'message': 'Invalid server response', 'raw_body': response.body};
      }

      // Handle different status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Request successful: ${response.statusCode}');
        return responseData;
      } else {
        debugPrint('❌ HTTP Error: ${response.statusCode}');
        debugPrint('❌ Response body: ${response.body}');
        
        // Handle specific server errors
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

  // Test connection to server
  Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing connection to server...');
      await _makeRequest('GET', '/test', expectSuccess: false);
      return true;
    } catch (e) {
      debugPrint('❌ Connection test failed: $e');
      return false;
    }
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    debugPrint('🔐 Attempting login for: $email');
    
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
  }

  Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    debugPrint('👤 Attempting registration for: ${userData['email']}');
    
    final response = await _makeRequest(
      'POST',
      '/register',
      headers: _getHeaders(),
      body: userData,
    );
    
    debugPrint('✅ Registration successful');
    return response;
  }

  Future<void> logout(String token) async {
    debugPrint('🚪 Logging out user');
    
    await _makeRequest(
      'POST',
      '/logout',
      headers: _getHeaders(token: token),
    );
    
    debugPrint('✅ Logout successful');
  }

  // User data methods with improved error handling
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

  // FIXED: UPDATE PROFILE METHOD
  Future<Map<String, dynamic>> updateProfile(String token, Map<String, String> userData, {String? endpoint}) async {
    debugPrint('📝 Updating user profile');
    
    try {
      final response = await _makeRequest(
        'PUT',
        endpoint ?? '/profile',
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

  // Enhanced wallet method with fallback behavior
  Future<Map<String, dynamic>> getWallet(String token, {String? endpoint}) async {
    debugPrint('💰 Getting wallet data');
    
    try {
      final response = await _makeRequest(
        'GET',
        endpoint ?? '/wallet',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ Wallet data retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get wallet data: $e');
      
      if (e.toString().contains('does not exist') || e.toString().contains('pengembangan')) {
        debugPrint('⚠️ Wallet endpoint not available, using fallback');
        
        return {
          'success': false,
          'message': 'Wallet service temporarily unavailable',
          'balance_rp': 0,
          'balance_koin': 0,
          'data': {
            'balance_rp': 0,
            'balance_koin': 0,
          }
        };
      }
      
      rethrow;
    }
  }

  // FIXED: TRANSACTION METHODS
  Future<List<Transaction>> getTransactions(String token) async {
    debugPrint('📊 Getting transactions');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/transactions',
        headers: _getHeaders(token: token),
      );
      
      // FIXED: Proper handling of transaction data
      final transactionsData = response['data'] ?? response['transactions'] ?? [];
      final List<dynamic> transactionsList = transactionsData is List ? transactionsData : [];
      
      final transactions = transactionsList.map((data) {
        try {
          return Transaction.fromJson(data);
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
        debugPrint('⚠️ Transactions endpoint not available, using fallback');
        return <Transaction>[];
      }
      
      rethrow;
    }
  }

  // FIXED: SCAN HISTORY METHODS
  Future<Map<String, dynamic>> getScanHistory(String token) async {
    debugPrint('📊 Getting scan history');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/scan-history',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ Scan history retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get scan history: $e');
      
      if (e.toString().contains('does not exist') || e.toString().contains('pengembangan')) {
        debugPrint('⚠️ Scan history endpoint not available, using fallback');
        return {
          'success': false,
          'message': 'Scan history temporarily unavailable',
          'data': [],
          'history': []
        };
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getScanStats(String token) async {
    debugPrint('📈 Getting scan statistics');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/scan-stats',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ Scan stats retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get scan stats: $e');
      
      if (e.toString().contains('does not exist') || e.toString().contains('pengembangan')) {
        debugPrint('⚠️ Scan stats endpoint not available, using fallback');
        return {
          'success': false,
          'message': 'Scan statistics temporarily unavailable',
          'data': {
            'total_scans': 0,
            'total_points': 0,
            'recent_scans': [],
          }
        };
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTransactionHistory(String token) async {
    debugPrint('📊 Getting transaction history');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/transaction-history',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ Transaction history retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get transaction history: $e');
      
      if (e.toString().contains('does not exist') || e.toString().contains('pengembangan')) {
        debugPrint('⚠️ Transaction history endpoint not available, using fallback');
        return {
          'success': false,
          'message': 'Transaction history temporarily unavailable',
          'data': [],
          'transactions': []
        };
      }
      
      rethrow;
    }
  }

  // FIXED: GENERAL HISTORY METHOD
  Future<List<Map<String, dynamic>>> getHistory(String token, {String? type}) async {
    debugPrint('📜 Getting general history');
    
    try {
      String endpoint = '/history';
      if (type != null) {
        endpoint += '?type=$type';
      }
      
      final response = await _makeRequest(
        'GET',
        endpoint,
        headers: _getHeaders(token: token),
      );
      
      // FIXED: Proper handling of history data
      final historyData = response['data'] ?? response['history'] ?? [];
      final List<dynamic> historyList = historyData is List ? historyData : [];
      
      debugPrint('✅ History retrieved successfully: ${historyList.length} items');
      return historyList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get history: $e');
      
      if (e.toString().contains('does not exist') || e.toString().contains('pengembangan')) {
        debugPrint('⚠️ History endpoint not available, using fallback');
        return <Map<String, dynamic>>[];
      }
      
      rethrow;
    }
  }

  // FIXED: DROPBOX METHODS
  Future<List<Map<String, dynamic>>> getDropboxes(String token) async {
    debugPrint('📍 Getting dropbox locations');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/dropboxes',
        headers: _getHeaders(token: token),
      );
      
      // FIXED: Proper handling of dropbox data
      final dropboxData = response['data'] ?? response['dropboxes'] ?? [];
      final List<dynamic> dropboxList = dropboxData is List ? dropboxData : [];
      
      debugPrint('✅ Dropbox locations retrieved successfully: ${dropboxList.length}');
      return dropboxList.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get dropbox locations: $e');
      
      if (e.toString().contains('does not exist') || e.toString().contains('pengembangan')) {
        debugPrint('⚠️ Dropbox locations endpoint not available, using fallback');
        return <Map<String, dynamic>>[];
      }
      
      rethrow;
    }
  }

  // FIXED: SCAN CONFIRMATION METHOD
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
        '/confirm-scan',
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

  // Enhanced transfer method
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
        '/transfer',
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

  // Enhanced topup method
  Future<Map<String, dynamic>> topupRequest(
  String token, {
  required double amount,
  required String method,
}) async {
  debugPrint('💰 Creating topup request: amount=$amount, method=$method');
  
  try {
    // FIXED: Ubah dari POST ke GET dengan query parameters
    final queryParams = {
      'amount': amount.toString(),
      'method': method,
    };
    
    final uri = Uri.parse('$baseUrl/topup').replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: _getHeaders(token: token),
    ).timeout(timeoutDuration);

    debugPrint('🌐 HTTP response received: ${response.statusCode}');
    
    Map<String, dynamic> responseData;
    try {
      responseData = jsonDecode(response.body);
    } catch (e) {
      debugPrint('❌ Failed to parse JSON response: ${response.body}');
      responseData = {'message': 'Invalid server response', 'raw_body': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('✅ Topup request created successfully');
      return responseData;
    } else {
      String errorMessage = _getErrorMessage(response.statusCode, responseData);
      throw Exception(errorMessage);
    }
    
  } catch (e) {
    debugPrint('❌ Topup request failed: $e');
    rethrow;
  }
}

  // FIXED: Enhanced exchange coins method
  Future<Map<String, dynamic>> exchangeCoins(
    String token, {
    required int coinAmount,
  }) async {
    debugPrint('🪙 Attempting to exchange coins: $coinAmount');
    
    try {
      final response = await _makeRequest(
        'POST',
        '/exchange-coins',
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

  // Submit waste deposit
  Future<Map<String, dynamic>> submitWasteDeposit(
    String token, {
    required int dropboxId,
    required String wasteType,
    required double weight,
    String? description,
  }) async {
    debugPrint('♻️ Submitting waste deposit to dropbox $dropboxId');
    
    try {
      final response = await _makeRequest(
        'POST',
        '/waste-deposit',
        headers: _getHeaders(token: token),
        body: {
          'dropbox_id': dropboxId,
          'waste_type': wasteType,
          'weight': weight,
          if (description != null && description.isNotEmpty) 'description': description,
        },
      );
      
      debugPrint('✅ Waste deposit submitted successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Waste deposit submission failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkToken(String token) async {
    return await _makeRequest('GET', '/check-token', headers: _getHeaders(token: token));
  }
}