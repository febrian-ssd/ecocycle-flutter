// lib/services/api_service.dart - FIXED API SERVICE
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:ecocycle_app/models/transaction.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class ApiService {
  static const String _baseUrl = 'https://ecocylce.my.id/api';
  static const String _fallbackUrl = 'http://ecocylce.my.id/api';
  
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
      debugPrint('🌐 Response body length: ${response.body.length}');
      
      // ENHANCED: Log full response body for debugging
      debugPrint('📝 Full response body: ${response.body}');
      
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

  Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('🔍 Handling response: ${response.statusCode}');
    debugPrint('🔍 Response URL: ${response.request?.url}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final responseData = json.decode(response.body);
        debugPrint('✅ Response parsed successfully');
        debugPrint('📊 Response data type: ${responseData.runtimeType}');
        debugPrint('📊 Response keys: ${responseData is Map ? responseData.keys : 'Not a Map'}');
        
        if (responseData is Map<String, dynamic>) {
          return responseData;
        } else {
          return {'data': responseData};
        }
      } catch (e) {
        debugPrint('❌ Failed to parse JSON: $e');
        debugPrint('📝 Raw response: ${response.body}');
        throw Exception('Response server tidak valid (bukan JSON)');
      }
    } else {
      debugPrint('❌ HTTP Error: ${response.statusCode}');
      debugPrint('📝 Error body: ${response.body}');
      
      try {
        final errorData = json.decode(response.body);
        String errorMessage = errorData['message'] ?? 'Terjadi kesalahan server';
        
        switch (response.statusCode) {
          case 401:
            errorMessage = 'Email atau password salah';
            break;
          case 422:
            errorMessage = errorData['message'] ?? 'Data tidak valid';
            if (errorData['errors'] != null) {
              debugPrint('📝 Validation errors: ${errorData['errors']}');
            }
            break;
          case 404:
            errorMessage = 'Data tidak ditemukan';
            break;
          case 500:
            errorMessage = 'Server sedang bermasalah. Coba lagi nanti.';
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

  // AUTH ENDPOINTS
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    debugPrint('🔐 Logging in user: $email');
    
    final requestBody = {
      'email': email,
      'password': password,
    };
    
    debugPrint('📤 Login request body: $requestBody');
    
    // Try HTTPS first
    try {
      final url = Uri.parse('$_baseUrl/login');
      debugPrint('🌐 Trying HTTPS login: $url');
      
      final response = await _makeRequest(() => http.post(
        url,
        headers: _getHeaders(),
        body: json.encode(requestBody),
      ));

      final result = _handleResponse(response);
      debugPrint('✅ HTTPS login response processed');
      
      return _normalizeLoginResponse(result);
      
    } catch (e) {
      debugPrint('❌ HTTPS login failed: $e');
      
      // Try HTTP fallback
      if (e.toString().contains('301') || e.toString().contains('302')) {
        debugPrint('🔄 Trying HTTP fallback due to redirect...');
        
        try {
          final fallbackUrl = Uri.parse('$_fallbackUrl/login');
          debugPrint('🌐 Trying HTTP login: $fallbackUrl');
          
          final response = await _makeRequest(() => http.post(
            fallbackUrl,
            headers: _getHeaders(),
            body: json.encode(requestBody),
          ));

          final result = _handleResponse(response);
          debugPrint('✅ HTTP fallback login response processed');
          
          return _normalizeLoginResponse(result);
          
        } catch (fallbackError) {
          debugPrint('❌ HTTP fallback also failed: $fallbackError');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  Map<String, dynamic> _normalizeLoginResponse(Map<String, dynamic> response) {
    debugPrint('🔧 Normalizing login response...');
    debugPrint('📊 Original response: $response');
    
    String? token;
    Map<String, dynamic>? user;
    
    // Check various possible token locations
    if (response['token'] != null) {
      token = response['token'].toString();
      debugPrint('✅ Found token in root');
    } else if (response['access_token'] != null) {
      token = response['access_token'].toString();
      debugPrint('✅ Found access_token in root');
    } else if (response['data'] != null && response['data'] is Map) {
      final data = response['data'] as Map<String, dynamic>;
      if (data['token'] != null) {
        token = data['token'].toString();
        debugPrint('✅ Found token in data');
      } else if (data['access_token'] != null) {
        token = data['access_token'].toString();
        debugPrint('✅ Found access_token in data');
      }
    }
    
    // Check various possible user locations
    if (response['user'] != null) {
      user = response['user'] is Map<String, dynamic> 
          ? response['user'] 
          : Map<String, dynamic>.from(response['user']);
      debugPrint('✅ Found user in root');
    } else if (response['data'] != null && response['data'] is Map) {
      final data = response['data'] as Map<String, dynamic>;
      if (data['user'] != null) {
        user = data['user'] is Map<String, dynamic> 
            ? data['user'] 
            : Map<String, dynamic>.from(data['user']);
        debugPrint('✅ Found user in data');
      }
    }
    
    debugPrint('🔍 Final extracted token: ${token?.substring(0, 20)}...');
    debugPrint('🔍 Final extracted user: ${user?.keys}');
    
    return {
      'token': token,
      'user': user,
      'original_response': response,
    };
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    debugPrint('📝 Registering user: $email');
    final url = Uri.parse('$_baseUrl/register');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(),
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    ));

    final result = _handleResponse(response);
    return _normalizeLoginResponse(result);
  }

  Future<void> logout(String token) async {
    debugPrint('🚪 Logging out user');
    final url = Uri.parse('$_baseUrl/logout');
    
    await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
    ));
    
    debugPrint('✅ Logout successful');
  }

  // USER PROFILE
  Future<Map<String, dynamic>> getProfile(String token) async {
    debugPrint('👤 Getting user profile');
    final url = Uri.parse('$_baseUrl/profile');
    
    final response = await _makeRequest(() => http.get(
      url,
      headers: _getHeaders(token: token),
    ));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile(String token, {
    String? name,
    String? email,
    String? password,
  }) async {
    debugPrint('✏️ Updating user profile');
    final url = Uri.parse('$_baseUrl/profile');
    
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (password != null) body['password'] = password;

    final response = await _makeRequest(() => http.put(
      url,
      headers: _getHeaders(token: token),
      body: json.encode(body),
    ));

    return _handleResponse(response);
  }

  // DROPBOX ENDPOINTS
  Future<List<Map<String, dynamic>>> getDropboxes(String token) async {
    debugPrint('📍 Getting dropboxes');
    final url = Uri.parse('$_baseUrl/dropboxes');
    
    final response = await _makeRequest(() => http.get(
      url,
      headers: _getHeaders(token: token),
    ));

    final responseData = _handleResponse(response);
    final dropboxes = responseData['data'] as List? ?? responseData as List? ?? [];
    
    return dropboxes.cast<Map<String, dynamic>>();
  }

  // SCAN ENDPOINTS
  Future<Map<String, dynamic>> scanQR(String token, String qrCode) async {
    debugPrint('📱 Scanning QR code');
    final url = Uri.parse('$_baseUrl/scan');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode({
        'qr_code': qrCode,
      }),
    ));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> confirmScan(String token, {
    required String dropboxCode,
    required String wasteType,
    required double weight,
  }) async {
    debugPrint('✅ Confirming scan');
    final url = Uri.parse('$_baseUrl/scan/confirm');
    
    final requestBody = {
      'dropbox_code': dropboxCode,
      'waste_type': wasteType,
      'weight': weight,
    };
    
    debugPrint('📤 Confirm scan request: $requestBody');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode(requestBody),
    ));

    return _handleResponse(response);
  }

  // HISTORY ENDPOINTS
  Future<List<Map<String, dynamic>>> getHistory(String token) async {
    debugPrint('📜 Getting history');
    final url = Uri.parse('$_baseUrl/history');
    
    final response = await _makeRequest(() => http.get(
      url,
      headers: _getHeaders(token: token),
    ));

    final responseData = _handleResponse(response);
    final history = responseData['data'] as List? ?? responseData as List? ?? [];
    
    return history.cast<Map<String, dynamic>>();
  }

  // ECOPAY/WALLET ENDPOINTS
  Future<Map<String, dynamic>> getWallet(String token) async {
    debugPrint('💰 Getting wallet data');
    final url = Uri.parse('$_baseUrl/wallet');
    
    final response = await _makeRequest(() => http.get(
      url,
      headers: _getHeaders(token: token),
    ));
    
    final responseData = _handleResponse(response);
    
    return {
      'balance_rp': ConversionUtils.toDouble(responseData['balance_rp'] ?? responseData['data']?['balance_rp']),
      'balance_coins': ConversionUtils.toInt(responseData['balance_coins'] ?? responseData['data']?['balance_coins']),
      'formatted_balance_rp': responseData['formatted_balance_rp'] ?? 'Rp 0',
    };
  }

  Future<List<Transaction>> getTransactions(String token) async {
    debugPrint('📊 Getting transactions');
    final url = Uri.parse('$_baseUrl/transactions');
    
    final response = await _makeRequest(() => http.get(
      url,
      headers: _getHeaders(token: token),
    ));

    final responseData = _handleResponse(response);
    final transactionsList = responseData['data'] as List? ?? responseData as List? ?? [];
    
    return transactionsList
        .map((json) => Transaction.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> transfer(String token, {
    required String email,
    required double amount,
    String? description,
  }) async {
    debugPrint('💸 Making transfer');
    final url = Uri.parse('$_baseUrl/transfer');
    
    final requestBody = {
      'email': email,
      'amount': amount,
      'description': description ?? '',
    };
    
    debugPrint('📤 Transfer request: $requestBody');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode(requestBody),
    ));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> exchangeCoins(String token, {
    required int coins,
  }) async {
    debugPrint('🔄 Exchanging coins: $coins');
    final url = Uri.parse('$_baseUrl/exchange-coins');
    
    final requestBody = {
      'coins': coins,
    };
    
    debugPrint('📤 Exchange coins request: $requestBody');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode(requestBody),
    ));

    final result = _handleResponse(response);
    
    // Ensure we return success flag
    return {
      'success': true,
      'message': result['message'] ?? 'Berhasil menukar coins',
      'data': result['data'] ?? result,
    };
  }

  Future<Map<String, dynamic>> topupRequest(String token, {
    required double amount,
    required String method,
  }) async {
    debugPrint('📈 Creating topup request');
    final url = Uri.parse('$_baseUrl/topup-request');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode({
        'amount': amount,
        'method': method,
      }),
    ));

    return _handleResponse(response);
  }

  Future<List<Map<String, dynamic>>> getTopupRequests(String token) async {
    debugPrint('📋 Getting topup requests');
    final url = Uri.parse('$_baseUrl/topup-requests');
    
    final response = await _makeRequest(() => http.get(
      url,
      headers: _getHeaders(token: token),
    ));

    final responseData = _handleResponse(response);
    final requests = responseData['data'] as List? ?? responseData as List? ?? [];
    
    return requests.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> uploadPaymentProof(
    String token, 
    int topupRequestId, 
    File imageFile
  ) async {
    debugPrint('📤 Uploading payment proof');
    final url = Uri.parse('$_baseUrl/topup-request/$topupRequestId/upload-proof');
    
    final request = http.MultipartRequest('POST', url);
    request.headers.addAll(_getHeaders(token: token));
    
    final multipartFile = await http.MultipartFile.fromPath(
      'payment_proof',
      imageFile.path,
    );
    
    request.files.add(multipartFile);
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    return _handleResponse(response);
  }
}