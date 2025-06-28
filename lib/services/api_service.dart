// lib/services/api_service.dart
import 'dart:async';
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
      final response = await http.get(Uri.parse('$baseUrl/health'), headers: _getHeaders()).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> _makeRequest(String method, String endpoint, {Map<String, String>? headers, Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    try {
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(timeoutDuration);
          break;
        case 'POST':
          response = await http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(timeoutDuration);
          break;
        case 'PUT':
           response = await http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(timeoutDuration);
           break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Server error: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Silakan periksa koneksi Anda.');
    } on TimeoutException {
      throw Exception('Koneksi timeout. Server tidak merespons tepat waktu.');
    } catch (e) {
      rethrow;
    }
  }

  // === AUTHENTICATION ===
  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _makeRequest('POST', '/login', headers: _getHeaders(), body: {'email': email, 'password': password});
  }

  Future<Map<String, dynamic>> register(Map<String, String> userData) async {
    return await _makeRequest('POST', '/register', headers: _getHeaders(), body: userData);
  }

  Future<void> logout(String token) async {
    await _makeRequest('POST', '/auth/logout', headers: _getHeaders(token: token));
  }

  // === USER DATA ===
  Future<Map<String, dynamic>> getUser(String token) async {
    return await _makeRequest('GET', '/auth/user', headers: _getHeaders(token: token));
  }
  
  Future<Map<String, dynamic>> updateProfile(String token, Map<String, String> userData, {required String endpoint}) async {
    return await _makeRequest('PUT', endpoint, headers: _getHeaders(token: token), body: userData);
  }

  // === WALLET & TRANSACTIONS ===
  Future<Map<String, dynamic>> getWallet(String token, {required String endpoint}) async {
    final response = await _makeRequest('GET', endpoint, headers: _getHeaders(token: token));
    return response['data'] ?? response;
  }

  Future<List<Transaction>> getTransactions(String token) async {
    final response = await _makeRequest('GET', '/user/transactions', headers: _getHeaders(token: token));
    List<dynamic> data = response['data'] ?? [];
    return data.map((item) => Transaction.fromJson(item)).toList();
  }
  
  Future<Map<String, dynamic>> topupRequest(String token, {required double amount, required String method}) async {
    return await _makeRequest('POST', '/user/topup', headers: _getHeaders(token: token), body: {'amount': amount, 'payment_method': method});
  }
  
  Future<Map<String, dynamic>> transfer(String token, {required String email, required double amount, String? description}) async {
    return await _makeRequest('POST', '/user/transfer', headers: _getHeaders(token: token), body: {'email': email, 'amount': amount, 'description': description});
  }
  
  Future<Map<String, dynamic>> exchangeCoins(String token, {required int coinAmount}) async {
    return await _makeRequest('POST', '/user/exchange-coins', headers: _getHeaders(token: token), body: {'coin_amount': coinAmount});
  }

  // === DROPBOX & SCAN ===
  Future<List<Map<String, dynamic>>> getDropboxes(String token) async {
    final response = await _makeRequest('GET', '/dropboxes', headers: _getHeaders(token: token));
    final data = response['data'] ?? response['dropboxes'];
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    }
    return [];
  }

  Future<Map<String, dynamic>> confirmScan(String token, {required String dropboxCode, required String wasteType, required double weight}) async {
    return await _makeRequest('POST', '/user/scan/confirm', headers: _getHeaders(token: token), body: {'dropbox_code': dropboxCode, 'waste_type': wasteType, 'weight': weight});
  }
  
  // === HISTORY ===
  Future<List<Map<String, dynamic>>> getHistory(String token, {String? type}) async {
    String endpoint = '/user/history';
    if (type != null) {
      endpoint += '?type=$type';
    }
    final response = await _makeRequest('GET', endpoint, headers: _getHeaders(token: token));
    final data = response['data'] ?? response['history'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }
}