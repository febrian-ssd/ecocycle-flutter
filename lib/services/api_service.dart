// lib/services/api_service.dart - RESTORED LARAVEL CONNECTIVITY
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

  Future<bool> testConnection() async {
    try {
      debugPrint('🔍 Testing Laravel connection...');
      final response = await http.get(
        Uri.parse('$baseUrl/test'),
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 5));
      
      bool isConnected = response.statusCode == 200;
      debugPrint('🔍 Laravel connection: $isConnected');
      return isConnected;
    } catch (e) {
      debugPrint('❌ Laravel connection failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint,
    {Map<String, String>? headers, 
     Map<String, dynamic>? body}) async {
    
    final uri = Uri.parse('$baseUrl$endpoint');
    debugPrint('🌐 Laravel $method: $uri');
    
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

      debugPrint('🌐 Laravel response: ${response.statusCode}');
      
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        debugPrint('❌ Laravel JSON parse error: ${response.body}');
        throw Exception('Server mengirim response yang tidak valid');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Laravel request successful');
        return responseData;
      } else {
        debugPrint('❌ Laravel HTTP Error: ${response.statusCode}');
        String errorMessage = _getErrorMessage(response.statusCode, responseData);
        throw Exception(errorMessage);
      }
      
    } on SocketException {
      debugPrint('❌ Network error: No internet connection');
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi.');
    } on HttpException {
      debugPrint('❌ HTTP error occurred');
      throw Exception('Terjadi kesalahan jaringan. Coba lagi nanti.');
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
        return responseData['message'] ?? 'Server sedang bermasalah. Coba lagi nanti.';
      case 502:
      case 503:
      case 504:
        return 'Server sedang maintenance. Coba lagi nanti.';
      default:
        return responseData['message'] ?? 'Terjadi kesalahan yang tidak diketahui';
    }
  }

  // === AUTHENTICATION === //
  Future<Map<String, dynamic>> login(String email, String password) async {
    debugPrint('🔐 Laravel login for: $email');
    
    final response = await _makeRequest(
      'POST',
      '/auth/login',
      headers: _getHeaders(),
      body: {
        'email': email,
        'password': password,
      },
    );
    
    debugPrint('✅ Laravel login successful');
    return response;
  }

  Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    debugPrint('👤 Laravel registration for: ${userData['email']}');
    
    final response = await _makeRequest(
      'POST',
      '/auth/register',
      headers: _getHeaders(),
      body: userData,
    );
    
    debugPrint('✅ Laravel registration successful');
    return response;
  }

  Future<void> logout(String token) async {
    debugPrint('🚪 Laravel logout');
    
    try {
      await _makeRequest(
        'POST',
        '/auth/logout',
        headers: _getHeaders(token: token),
      );
      debugPrint('✅ Laravel logout successful');
    } catch (e) {
      debugPrint('⚠️ Laravel logout failed (continuing anyway): $e');
    }
  }

  Future<Map<String, dynamic>> checkToken(String token) async {
    debugPrint('🔍 Laravel token check');
    
    final response = await _makeRequest(
      'GET', 
      '/auth/me', 
      headers: _getHeaders(token: token)
    );
    
    debugPrint('✅ Laravel token valid');
    return response;
  }

  // === USER DATA === //
  Future<Map<String, dynamic>> getUser(String token) async {
    debugPrint('👤 Laravel get user');
    
    final response = await _makeRequest(
      'GET',
      '/auth/user',
      headers: _getHeaders(token: token),
    );
    
    debugPrint('✅ Laravel user data retrieved');
    return response;
  }

  Future<Map<String, dynamic>> updateProfile(String token, Map<String, String> userData, {String? endpoint}) async {
    debugPrint('📝 Laravel update profile');
    
    final response = await _makeRequest(
      'PUT',
      '/user/profile',
      headers: _getHeaders(token: token),
      body: userData,
    );
    
    debugPrint('✅ Laravel profile updated');
    return response;
  }

  // === WALLET & TRANSACTIONS === //
  Future<Map<String, dynamic>> getWallet(String token, {String? endpoint}) async {
    debugPrint('💰 Laravel get wallet');
    
    final response = await _makeRequest(
      'GET',
      '/user/wallet',
      headers: _getHeaders(token: token),
    );
    
    debugPrint('✅ Laravel wallet retrieved');
    return response;
  }

  Future<List<Transaction>> getTransactions(String token) async {
    debugPrint('📊 Laravel get transactions');
    
    final response = await _makeRequest(
      'GET',
      '/user/transactions',
      headers: _getHeaders(token: token),
    );
    
    List<dynamic> transactionsData = response['data'] ?? response['transactions'] ?? [];
    
    final transactions = transactionsData.map((data) {
      try {
        return Transaction.fromJson(data as Map<String, dynamic>);
      } catch (e) {
        debugPrint('❌ Failed to parse transaction: $data');
        return null;
      }
    }).where((t) => t != null).cast<Transaction>().toList();
    
    debugPrint('✅ Laravel transactions retrieved: ${transactions.length}');
    return transactions;
  }

  Future<Map<String, dynamic>> transfer(
    String token, {
    required String email,
    required double amount,
    String? description,
  }) async {
    debugPrint('💸 Laravel transfer to: $email, amount: $amount');
    
    final response = await _makeRequest(
      'POST',
      '/user/transfer',
      headers: _getHeaders(token: token),
      body: {
        'recipient_email': email,
        'amount': amount,
        if (description != null && description.isNotEmpty) 'description': description,
      },
    );
    
    debugPrint('✅ Laravel transfer successful');
    return response;
  }

  Future<Map<String, dynamic>> topupRequest(
    String token, {
    required double amount,
    required String method,
  }) async {
    debugPrint('💰 Laravel topup request: $amount, $method');
    
    final response = await _makeRequest(
      'POST',
      '/user/topup-request',
      headers: _getHeaders(token: token),
      body: {
        'amount': amount,
        'payment_method': method,
      },
    );
    
    debugPrint('✅ Laravel topup request created');
    return response;
  }

  Future<Map<String, dynamic>> exchangeCoins(
    String token, {
    required int coinAmount,
  }) async {
    debugPrint('🪙 Laravel exchange coins: $coinAmount');
    
    final response = await _makeRequest(
      'POST',
      '/user/exchange-coins',
      headers: _getHeaders(token: token),
      body: {
        'coin_amount': coinAmount,
      },
    );
    
    debugPrint('✅ Laravel coin exchange successful');
    return response;
  }

  // === DROPBOX & SCAN === //
  Future<List<Map<String, dynamic>>> getDropboxes(String token) async {
    debugPrint('📍 Laravel get dropboxes');
    
    final response = await _makeRequest(
      'GET',
      '/dropboxes',
      headers: _getHeaders(token: token),
    );
    
    List<dynamic> dropboxData = response['data'] ?? response['dropboxes'] ?? response;
    
    debugPrint('✅ Laravel dropboxes retrieved: ${dropboxData.length}');
    return dropboxData.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> confirmScan(
    String token, {
    required String dropboxCode,
    required String wasteType,
    required double weight,
  }) async {
    debugPrint('✅ Laravel confirm scan: $dropboxCode');
    
    final response = await _makeRequest(
      'POST',
      '/user/scan',
      headers: _getHeaders(token: token),
      body: {
        'dropbox_id': dropboxCode,
        'waste_type': wasteType,
        'weight_g': weight,
      },
    );
    
    debugPrint('✅ Laravel scan confirmed');
    return response;
  }

  // === HISTORY === //
  Future<List<Map<String, dynamic>>> getHistory(String token, {String? type}) async {
    debugPrint('📜 Laravel get history');
    
    String endpoint = '/user/history';
    if (type != null) {
      endpoint += '?type=$type';
    }
    
    final response = await _makeRequest(
      'GET',
      endpoint,
      headers: _getHeaders(token: token),
    );
    
    List<dynamic> historyData = response['data'] ?? response['history'] ?? [];
    
    debugPrint('✅ Laravel history retrieved: ${historyData.length}');
    return historyData.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getScanHistory(String token) async {
    debugPrint('📊 Laravel get scan history');
    
    final response = await _makeRequest(
      'GET',
      '/user/scan-history',
      headers: _getHeaders(token: token),
    );
    
    debugPrint('✅ Laravel scan history retrieved');
    return response;
  }

  Future<Map<String, dynamic>> getScanStats(String token) async {
    debugPrint('📈 Laravel get scan stats');
    
    final response = await _makeRequest(
      'GET',
      '/user/scan-stats',
      headers: _getHeaders(token: token),
    );
    
    debugPrint('✅ Laravel scan stats retrieved');
    return response;
  }

  Future<Map<String, dynamic>> getTransactionHistory(String token) async {
    debugPrint('💳 Laravel get transaction history');
    
    final response = await _makeRequest(
      'GET',
      '/user/transaction-history',
      headers: _getHeaders(token: token),
    );
    
    debugPrint('✅ Laravel transaction history retrieved');
    return response;
  }
}