// lib/services/api_service.dart - COMPLETE UPDATE
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ecocycle_app/models/transaction.dart';

class ApiService {
  static const String baseUrl = 'https://ecocylce.my.id/api'; // Keep as requested
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
      final response = await http.get(
        Uri.parse('$baseUrl/health'), 
        headers: _getHeaders()
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _makeRequest(
    String method, 
    String endpoint, 
    {Map<String, String>? headers, Map<String, dynamic>? body}
  ) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
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
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Handle standardized response format
        if (responseData is Map<String, dynamic> && responseData.containsKey('success')) {
          return responseData;
        }
        
        // Handle legacy format - wrap it
        return {
          'success': true,
          'data': responseData,
          'message': 'Success'
        };
      } else {
        // Handle error response
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('message')) {
            throw Exception(responseData['message']);
          } else if (responseData.containsKey('errors')) {
            final errors = responseData['errors'];
            if (errors is Map) {
              final firstError = errors.values.first;
              throw Exception(firstError is List ? firstError.first : firstError.toString());
            }
          }
        }
        throw Exception('Server error: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your connection.');
    } on TimeoutException {
      throw Exception('Connection timeout. Server not responding.');
    } catch (e) {
      rethrow;
    }
  }

  // === AUTHENTICATION ===
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _makeRequest(
      'POST', 
      '/login', 
      headers: _getHeaders(), 
      body: {'email': email, 'password': password}
    );
    return response['data'] ?? response;
  }

  Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    final response = await _makeRequest(
      'POST', 
      '/register', 
      headers: _getHeaders(), 
      body: userData
    );
    return response['data'] ?? response;
  }

  Future<void> logout(String token) async {
    await _makeRequest('POST', '/auth/logout', headers: _getHeaders(token: token));
  }

  // === USER DATA ===
  Future<Map<String, dynamic>> getUser(String token) async {
    final response = await _makeRequest('GET', '/auth/user', headers: _getHeaders(token: token));
    return response['data'] ?? response;
  }
  
  Future<Map<String, dynamic>> updateProfile(
    String token, 
    Map<String, String> userData, 
    {required String endpoint}
  ) async {
    final response = await _makeRequest(
      'PUT', 
      endpoint, 
      headers: _getHeaders(token: token), 
      body: userData
    );
    return response['data'] ?? response;
  }

  // === WALLET & TRANSACTIONS ===
  Future<Map<String, dynamic>> getWallet(String token, {required String endpoint}) async {
    final response = await _makeRequest('GET', endpoint, headers: _getHeaders(token: token));
    return response['data'] ?? response;
  }

  Future<List<Transaction>> getTransactions(String token) async {
    final response = await _makeRequest('GET', '/user/transactions', headers: _getHeaders(token: token));
    final data = response['data'] ?? [];
    if (data is List) {
      return data.map((item) => Transaction.fromJson(item)).toList();
    }
    return [];
  }
  
  Future<Map<String, dynamic>> topupRequest(
    String token, 
    {required double amount, required String method}
  ) async {
    final response = await _makeRequest(
      'POST', 
      '/user/topup', 
      headers: _getHeaders(token: token), 
      body: {'amount': amount, 'payment_method': method}
    );
    return response['data'] ?? response;
  }
  
  Future<Map<String, dynamic>> transfer(
    String token, 
    {required String email, required double amount, String? description}
  ) async {
    final response = await _makeRequest(
      'POST', 
      '/user/transfer', 
      headers: _getHeaders(token: token), 
      body: {'email': email, 'amount': amount, 'description': description}
    );
    return response['data'] ?? response;
  }
  
  Future<Map<String, dynamic>> exchangeCoins(String token, {required int coinAmount}) async {
    final response = await _makeRequest(
      'POST', 
      '/user/exchange-coins', 
      headers: _getHeaders(token: token), 
      body: {'coin_amount': coinAmount}
    );
    return response['data'] ?? response;
  }

  // === DROPBOX & SCAN ===
  Future<List<Map<String, dynamic>>> getDropboxes(String token) async {
    final response = await _makeRequest('GET', '/dropboxes', headers: _getHeaders(token: token));
    final data = response['data'] ?? response;
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<Map<String, dynamic>> confirmScan(
    String token, 
    {required String dropboxCode, required String wasteType, required double weight}
  ) async {
    final response = await _makeRequest(
      'POST', 
      '/user/scan/confirm', 
      headers: _getHeaders(token: token), 
      body: {'dropbox_code': dropboxCode, 'waste_type': wasteType, 'weight': weight}
    );
    return response['data'] ?? response;
  }
  
  // === HISTORY ===
  Future<List<Map<String, dynamic>>> getHistory(String token, {String? type}) async {
    String endpoint = '/user/history';
    if (type != null) {
      endpoint += '?type=$type';
    }
    final response = await _makeRequest('GET', endpoint, headers: _getHeaders(token: token));
    final data = response['data'] ?? response;
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }
}