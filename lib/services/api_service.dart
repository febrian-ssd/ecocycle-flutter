// lib/services/api_service.dart - IMPROVED VERSION WITH BETTER ERROR HANDLING
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
        // Handle specific server method not found error
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

  // Enhanced wallet method with fallback behavior
  Future<Map<String, dynamic>> getWallet(String token) async {
    debugPrint('💰 Getting wallet data');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/wallet',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ Wallet data retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get wallet data: $e');
      
      // If the wallet endpoint doesn't exist, return dummy data or handle gracefully
      if (e.toString().contains('does not exist') || e.toString().contains('pengembangan')) {
        debugPrint('⚠️ Wallet endpoint not available, using fallback');
        
        // Return a mock wallet structure so the app doesn't crash
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

  // Enhanced transaction history method
  Future<Map<String, dynamic>> getTransactionHistory(String token) async {
    debugPrint('📊 Getting transaction history');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/transactions',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ Transaction history retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get transaction history: $e');
      
      // Return empty history if endpoint doesn't exist
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
      final response = await _makeRequest(
        'POST',
        '/topup',
        headers: _getHeaders(token: token),
        body: {
          'amount': amount,
          'method': method,
        },
      );
      
      debugPrint('✅ Topup request created successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Topup request failed: $e');
      rethrow;
    }
  }

  // Enhanced exchange coins method
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

  // Get dropbox locations
  Future<Map<String, dynamic>> getDropboxLocations(String token) async {
    debugPrint('📍 Getting dropbox locations');
    
    try {
      final response = await _makeRequest(
        'GET',
        '/dropboxes',
        headers: _getHeaders(token: token),
      );
      
      debugPrint('✅ Dropbox locations retrieved successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Failed to get dropbox locations: $e');
      
      // Return empty locations if endpoint doesn't exist
      if (e.toString().contains('does not exist') || e.toString().contains('pengembangan')) {
        debugPrint('⚠️ Dropbox locations endpoint not available, using fallback');
        return {
          'success': false,
          'message': 'Dropbox locations temporarily unavailable',
          'data': [],
          'dropboxes': []
        };
      }
      
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
}