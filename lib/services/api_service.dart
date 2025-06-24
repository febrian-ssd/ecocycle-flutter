// lib/services/api_service.dart - FIXED VERSION
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:ecocycle_app/models/transaction.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class ApiService {
  // FIXED: Corrected domain spelling and add multiple endpoints
  static const String _baseUrl = 'https://ecocycle.my.id/api';  // Fixed typo: ecocylce -> ecocycle
  static const String _fallbackUrl = 'http://ecocycle.my.id/api';
  static const String _localUrl = 'http://192.168.1.100:8000/api'; // Local testing
  
  static const Duration _timeout = Duration(seconds: 30);

  Map<String, String> _getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'EcoCycle-Flutter-App/1.0',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  Future<http.Response> _makeRequest(Future<http.Response> Function() request) async {
    try {
      debugPrint('🌐 Making HTTP request...');
      final response = await request().timeout(_timeout);
      debugPrint('🌐 HTTP response received: ${response.statusCode}');
      debugPrint('🌐 Response headers: ${response.headers}');
      
      // Log response body (truncated for large responses)
      String bodyPreview = response.body.length > 500 
          ? '${response.body.substring(0, 500)}...' 
          : response.body;
      debugPrint('🌐 Response body: $bodyPreview');
      
      return response;
    } on TimeoutException catch (e) {
      debugPrint('❌ TimeoutException: $e');
      throw Exception('Koneksi timeout. Periksa koneksi internet Anda.');
    } on SocketException catch (e) {
      debugPrint('❌ SocketException: $e');
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda.');
    } on HttpException catch (e) {
      debugPrint('❌ HttpException: $e');
      throw Exception('Gagal terhubung ke server. Coba lagi nanti.');
    } catch (e) {
      debugPrint('❌ General Exception: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Enhanced method to try multiple endpoints
  Future<http.Response> _tryMultipleEndpoints({
    required List<String> endpoints,
    required Future<http.Response> Function(String endpoint) requestBuilder,
  }) async {
    Exception? lastException;
    
    for (String endpoint in endpoints) {
      try {
        debugPrint('🔄 Trying endpoint: $endpoint');
        final response = await _makeRequest(() => requestBuilder(endpoint));
        debugPrint('✅ Success with endpoint: $endpoint');
        return response;
      } catch (e) {
        debugPrint('❌ Endpoint $endpoint failed: $e');
        lastException = e is Exception ? e : Exception(e.toString());
        continue;
      }
    }
    
    throw lastException ?? Exception('All endpoints failed');
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('🔍 Handling response: ${response.statusCode}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic>) {
          return responseData;
        } else {
          return {'data': responseData};
        }
      } catch (e) {
        debugPrint('❌ Failed to parse JSON: $e');
        throw Exception('Response server tidak valid (bukan JSON)');
      }
    } else {
      debugPrint('❌ HTTP Error: ${response.statusCode}');
      
      try {
        final errorData = json.decode(response.body);
        String errorMessage = errorData['message'] ?? 'Terjadi kesalahan server';
        
        switch (response.statusCode) {
          case 401:
            errorMessage = 'Email atau password salah';
            break;
          case 404:
            errorMessage = 'Endpoint tidak ditemukan. Periksa URL server.';
            break;
          case 405:
            errorMessage = 'Method tidak diizinkan. Periksa konfigurasi server.';
            break;
          case 422:
            errorMessage = errorData['message'] ?? 'Data tidak valid';
            break;
          case 500:
            errorMessage = 'Server sedang bermasalah. Coba lagi nanti.';
            break;
          case 502:
            errorMessage = 'Bad Gateway. Server sedang maintenance.';
            break;
          case 503:
            errorMessage = 'Service unavailable. Server overload.';
            break;
        }
        
        throw Exception(errorMessage);
      } catch (e) {
        if (e.toString().startsWith('Exception:')) {
          rethrow;
        }
        throw Exception('Server error (${response.statusCode})');
      }
    }
  }

  // FIXED: Top Up Request with multiple endpoint attempts
  Future<Map<String, dynamic>> topupRequest(String token, {
    required double amount,
    required String method,
  }) async {
    debugPrint('📈 Creating topup request for amount: $amount, method: $method');
    
    final requestBody = {
      'amount': amount,
      'method': method,
    };
    
    debugPrint('📤 Topup request body: $requestBody');
    
    // Try multiple endpoint variations for topup
    final endpoints = [
      '$_baseUrl/topup-request',
      '$_baseUrl/topup',
      '$_baseUrl/wallet/topup',
      '$_fallbackUrl/topup-request',
      '$_fallbackUrl/topup',
      '$_localUrl/topup-request', // For local testing
    ];
    
    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.post(
        Uri.parse(endpoint),
        headers: _getHeaders(token: token),
        body: json.encode(requestBody),
      ),
    );

    final result = _handleResponse(response);
    debugPrint('✅ Topup request successful');
    
    return {
      'success': true,
      'message': result['message'] ?? 'Permintaan top up berhasil dibuat',
      'data': result['data'] ?? result,
    };
  }

  // FIXED: Login with corrected domain
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 Logging in user: $email');
    
    final requestBody = {
      'email': email,
      'password': password,
    };
    
    // Fixed domain spelling and added more variations
    final endpoints = [
      '$_baseUrl/login',
      '$_baseUrl/auth/login', 
      '$_fallbackUrl/login',
      '$_fallbackUrl/auth/login',
      'https://ecocycle.my.id/login', // Direct without /api
      'http://ecocycle.my.id/login',
      '$_localUrl/login', // Local testing
    ];
    
    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.post(
        Uri.parse(endpoint),
        headers: _getHeaders(),
        body: json.encode(requestBody),
      ),
    );

    final result = _handleResponse(response);
    debugPrint('✅ Login successful');
    return _normalizeLoginResponse(result);
  }

  Map<String, dynamic> _normalizeLoginResponse(Map<String, dynamic> response) {
    debugPrint('🔧 Normalizing login response...');
    
    String? token;
    Map<String, dynamic>? user;
    
    // Check various possible token locations
    if (response['token'] != null) {
      token = response['token'].toString();
    } else if (response['access_token'] != null) {
      token = response['access_token'].toString();
    } else if (response['data'] != null && response['data'] is Map) {
      final data = response['data'] as Map<String, dynamic>;
      if (data['token'] != null) {
        token = data['token'].toString();
      } else if (data['access_token'] != null) {
        token = data['access_token'].toString();
      }
    }
    
    // Check various possible user locations
    if (response['user'] != null) {
      user = response['user'] is Map<String, dynamic> 
          ? response['user'] 
          : Map<String, dynamic>.from(response['user']);
    } else if (response['data'] != null && response['data'] is Map) {
      final data = response['data'] as Map<String, dynamic>;
      if (data['user'] != null) {
        user = data['user'] is Map<String, dynamic> 
            ? data['user'] 
            : Map<String, dynamic>.from(data['user']);
      }
    }
    
    return {
      'token': token,
      'user': user,
      'original_response': response,
    };
  }

  // FIXED: Register with corrected domain
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    debugPrint('📝 Registering user: $email');
    
    final endpoints = [
      '$_baseUrl/register',
      '$_baseUrl/auth/register',
      '$_fallbackUrl/register', 
      '$_fallbackUrl/auth/register',
      '$_localUrl/register',
    ];
    
    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.post(
        Uri.parse(endpoint),
        headers: _getHeaders(),
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      ),
    );

    final result = _handleResponse(response);
    return _normalizeLoginResponse(result);
  }

  // FIXED: All other methods with corrected base URLs
  Future<void> logout(String token) async {
    debugPrint('🚪 Logging out user');
    
    try {
      await _makeRequest(() => http.post(
        Uri.parse('$_baseUrl/logout'),
        headers: _getHeaders(token: token),
      ));
      
      debugPrint('✅ Logout successful');
    } catch (e) {
      debugPrint('⚠️ Logout failed: $e');
      // Don't throw error for logout failures
    }
  }

  // FIXED: Get dropboxes with enhanced error handling
  Future<List<Map<String, dynamic>>> getDropboxes(String token) async {
    debugPrint('📍 Getting dropboxes');
    
    final endpoints = [
      '$_baseUrl/dropboxes',
      '$_baseUrl/dropbox',
      '$_fallbackUrl/dropboxes',
      '$_localUrl/dropboxes',
    ];
    
    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.get(
        Uri.parse(endpoint),
        headers: _getHeaders(token: token),
      ),
    );

    final responseData = _handleResponse(response);
    final dropboxes = responseData['data'] as List? ?? responseData as List? ?? [];
    
    debugPrint('✅ Retrieved ${dropboxes.length} dropboxes');
    return dropboxes.cast<Map<String, dynamic>>();
  }

  // FIXED: Wallet endpoint
  Future<Map<String, dynamic>> getWallet(String token) async {
    debugPrint('💰 Getting wallet data');
    
    final endpoints = [
      '$_baseUrl/wallet',
      '$_baseUrl/user/wallet',
      '$_fallbackUrl/wallet',
      '$_localUrl/wallet',
    ];
    
    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.get(
        Uri.parse(endpoint),
        headers: _getHeaders(token: token),
      ),
    );
    
    final responseData = _handleResponse(response);
    
    return {
      'balance_rp': ConversionUtils.toDouble(responseData['balance_rp'] ?? responseData['data']?['balance_rp']),
      'balance_coins': ConversionUtils.toInt(responseData['balance_coins'] ?? responseData['data']?['balance_coins']),
      'formatted_balance_rp': responseData['formatted_balance_rp'] ?? 'Rp 0',
    };
  }

  // FIXED: Transfer with multiple endpoints
  Future<Map<String, dynamic>> transfer(String token, {
    required String email,
    required double amount,
    String? description,
  }) async {
    debugPrint('💸 Making transfer to: $email, amount: $amount');
    
    final requestBody = {
      'email': email,
      'amount': amount,
      'description': description ?? '',
    };
    
    final endpoints = [
      '$_baseUrl/transfer',
      '$_baseUrl/wallet/transfer',
      '$_fallbackUrl/transfer',
      '$_localUrl/transfer',
    ];
    
    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.post(
        Uri.parse(endpoint),
        headers: _getHeaders(token: token),
        body: json.encode(requestBody),
      ),
    );

    return _handleResponse(response);
  }

  // FIXED: Exchange coins
  Future<Map<String, dynamic>> exchangeCoins(String token, {
    required int coins,
  }) async {
    debugPrint('🔄 Exchanging coins: $coins');
    
    final requestBody = {
      'coins': coins,
    };
    
    final endpoints = [
      '$_baseUrl/exchange-coins',
      '$_baseUrl/wallet/exchange',
      '$_baseUrl/coins/exchange',
      '$_fallbackUrl/exchange-coins',
      '$_localUrl/exchange-coins',
    ];
    
    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.post(
        Uri.parse(endpoint),
        headers: _getHeaders(token: token),
        body: json.encode(requestBody),
      ),
    );

    final result = _handleResponse(response);
    
    return {
      'success': true,
      'message': result['message'] ?? 'Berhasil menukar coins',
      'data': result['data'] ?? result,
    };
  }

  // FIXED: Get transactions
  Future<List<Transaction>> getTransactions(String token) async {
    debugPrint('📊 Getting transactions');
    
    final endpoints = [
      '$_baseUrl/transactions',
      '$_baseUrl/wallet/transactions',
      '$_fallbackUrl/transactions',
      '$_localUrl/transactions',
    ];
    
    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.get(
        Uri.parse(endpoint),
        headers: _getHeaders(token: token),
      ),
    );

    final responseData = _handleResponse(response);
    final transactionsList = responseData['data'] as List? ?? responseData as List? ?? [];
    
    return transactionsList
        .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // FIXED: Get history
  Future<List<Map<String, dynamic>>> getHistory(String token) async {
    debugPrint('📜 Getting history');
    
    final endpoints = [
      '$_baseUrl/history',
      '$_baseUrl/user/history',
      '$_fallbackUrl/history',
      '$_localUrl/history',
    ];
    
    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.get(
        Uri.parse(endpoint),
        headers: _getHeaders(token: token),
      ),
    );

    final responseData = _handleResponse(response);
    final history = responseData['data'] as List? ?? responseData as List? ?? [];
    
    return history.cast<Map<String, dynamic>>();
  }

  // USER PROFILE METHODS - ADDED MISSING METHODS
  Future<Map<String, dynamic>> getProfile(String token) async {
    debugPrint('👤 Getting user profile');
    
    final endpoints = [
      '$_baseUrl/profile',
      '$_baseUrl/user/profile',
      '$_baseUrl/user',
      '$_fallbackUrl/profile',
      '$_localUrl/profile',
    ];
    
    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.get(
        Uri.parse(endpoint),
        headers: _getHeaders(token: token),
      ),
    );

    final responseData = _handleResponse(response);
    
    // Return user data directly or from 'data' wrapper
    return responseData['data'] ?? responseData;
  }

  Future<Map<String, dynamic>> updateProfile(String token, {
    String? name,
    String? email,
    String? password,
  }) async {
    debugPrint('✏️ Updating user profile');
    
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;

    final endpoints = [
      '$_baseUrl/profile',
      '$_baseUrl/user/profile',
      '$_baseUrl/user',
      '$_fallbackUrl/profile',
      '$_localUrl/profile',
    ];

    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.put(
        Uri.parse(endpoint),
        headers: _getHeaders(token: token),
        body: json.encode(body),
      ),
    );

    return _handleResponse(response);
  }

  // SCAN METHODS
  Future<Map<String, dynamic>> scanQR(String token, String qrCode) async {
    debugPrint('📱 Scanning QR code');
    
    final endpoints = [
      '$_baseUrl/scan',
      '$_baseUrl/qr/scan',
      '$_fallbackUrl/scan',
      '$_localUrl/scan',
    ];
    
    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.post(
        Uri.parse(endpoint),
        headers: _getHeaders(token: token),
        body: json.encode({'qr_code': qrCode}),
      ),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> confirmScan(String token, {
    required String dropboxCode,
    required String wasteType,
    required double weight,
  }) async {
    debugPrint('✅ Confirming scan');
    
    final requestBody = {
      'dropbox_code': dropboxCode,
      'waste_type': wasteType,
      'weight': weight,
    };
    
    debugPrint('📤 Confirm scan request: $requestBody');
    
    final endpoints = [
      '$_baseUrl/scan/confirm',
      '$_baseUrl/confirm-scan',
      '$_fallbackUrl/scan/confirm',
      '$_localUrl/scan/confirm',
    ];
    
    final response = await _tryMultipleEndpoints(
      endpoints: endpoints,
      requestBuilder: (endpoint) => http.post(
        Uri.parse(endpoint),
        headers: _getHeaders(token: token),
        body: json.encode(requestBody),
      ),
    );

    return _handleResponse(response);
  }

  // HISTORY METHODS - ADDED MISSING METHODS
  Future<Map<String, dynamic>> getScanHistory(String token) async {
    debugPrint('📜 Getting scan history');
    
    try {
      final endpoints = [
        '$_baseUrl/scan-history',
        '$_baseUrl/history/scan',
        '$_fallbackUrl/scan-history',
        '$_localUrl/scan-history',
      ];
      
      final response = await _tryMultipleEndpoints(
        endpoints: endpoints,
        requestBuilder: (endpoint) => http.get(
          Uri.parse(endpoint),
          headers: _getHeaders(token: token),
        ),
      );

      final responseData = _handleResponse(response);
      
      return {
        'data': responseData['data'] as List? ?? responseData as List? ?? [],
        'meta': responseData['meta'] ?? {},
      };
    } catch (e) {
      debugPrint('⚠️ getScanHistory failed, using fallback: $e');
      return await _getMockScanHistory(token);
    }
  }

  Future<Map<String, dynamic>> getScanStats(String token) async {
    debugPrint('📊 Getting scan statistics');
    
    try {
      final endpoints = [
        '$_baseUrl/scan-stats',
        '$_baseUrl/stats/scan',
        '$_fallbackUrl/scan-stats',
        '$_localUrl/scan-stats',
      ];
      
      final response = await _tryMultipleEndpoints(
        endpoints: endpoints,
        requestBuilder: (endpoint) => http.get(
          Uri.parse(endpoint),
          headers: _getHeaders(token: token),
        ),
      );

      final responseData = _handleResponse(response);
      
      return {
        'data': {
          'total_scans': ConversionUtils.toInt(responseData['total_scans'] ?? responseData['data']?['total_scans'] ?? 0),
          'total_coins_earned': ConversionUtils.toInt(responseData['total_coins_earned'] ?? responseData['data']?['total_coins_earned'] ?? 0),
          'total_waste_weight': ConversionUtils.toDouble(responseData['total_waste_weight'] ?? responseData['data']?['total_waste_weight'] ?? 0.0),
        }
      };
    } catch (e) {
      debugPrint('⚠️ getScanStats failed, using fallback: $e');
      return await _getMockScanStats(token);
    }
  }

  Future<Map<String, dynamic>> getTransactionHistory(String token) async {
    debugPrint('💰 Getting transaction history');
    
    try {
      final endpoints = [
        '$_baseUrl/transaction-history',
        '$_baseUrl/transactions/history',
        '$_fallbackUrl/transaction-history',
        '$_localUrl/transaction-history',
      ];
      
      final response = await _tryMultipleEndpoints(
        endpoints: endpoints,
        requestBuilder: (endpoint) => http.get(
          Uri.parse(endpoint),
          headers: _getHeaders(token: token),
        ),
      );

      final responseData = _handleResponse(response);
      
      return {
        'data': responseData['data'] as List? ?? responseData as List? ?? [],
        'meta': responseData['meta'] ?? {},
      };
    } catch (e) {
      debugPrint('⚠️ getTransactionHistory failed, using fallback: $e');
      return await _getMockTransactionHistory(token);
    }
  }

  // FALLBACK METHODS
  Future<Map<String, dynamic>> _getMockScanHistory(String token) async {
    debugPrint('🔄 Using fallback scan history data');
    
    try {
      final history = await getHistory(token);
      final scanHistory = history.where((item) => 
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
    } catch (e) {
      debugPrint('❌ Fallback scan history also failed: $e');
      return {'data': [], 'meta': {'total': 0}};
    }
  }

  Future<Map<String, dynamic>> _getMockScanStats(String token) async {
    debugPrint('🔄 Using fallback scan stats data');
    
    try {
      final history = await getHistory(token);
      int totalScans = 0;
      int totalCoinsEarned = 0;
      double totalWasteWeight = 0.0;
      
      for (var item in history) {
        if (item['type'] == 'scan' || 
            item['activity_type'] == 'scan' ||
            item.containsKey('waste_type')) {
          totalScans++;
          totalCoinsEarned += ConversionUtils.toInt(item['coins_earned'] ?? item['eco_coins'] ?? 0);
          totalWasteWeight += ConversionUtils.toDouble(item['weight'] ?? item['weight_g'] ?? 0);
        }
      }
      
      return {
        'data': {
          'total_scans': totalScans,
          'total_coins_earned': totalCoinsEarned,
          'total_waste_weight': totalWasteWeight,
        }
      };
    } catch (e) {
      debugPrint('❌ Fallback scan stats also failed: $e');
      return {
        'data': {
          'total_scans': 0,
          'total_coins_earned': 0,
          'total_waste_weight': 0.0,
        }
      };
    }
  }

  Future<Map<String, dynamic>> _getMockTransactionHistory(String token) async {
    debugPrint('🔄 Using fallback transaction history data');
    
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
    } catch (e) {
      debugPrint('❌ Fallback transaction history also failed: $e');
      return {'data': [], 'meta': {'total': 0}};
    }
  }

  // Additional debugging method
  Future<void> testConnection() async {
    debugPrint('🔍 Testing API connection...');
    
    final testEndpoints = [
      _baseUrl,
      _fallbackUrl,
      _localUrl,
    ];
    
    for (String baseUrl in testEndpoints) {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/test'),
          headers: _getHeaders(),
        ).timeout(const Duration(seconds: 10));
        
        debugPrint('✅ $baseUrl responded with: ${response.statusCode}');
      } catch (e) {
        debugPrint('❌ $baseUrl failed: $e');
      }
    }
  }
}