// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ecocycle_app/models/dropbox.dart';
import 'package:ecocycle_app/models/transaction.dart';

class ApiService {
  // Pastikan ini adalah domain asli Anda saat online
  final String _baseUrl = 'https://ecocylce.my.id/api';
  // Untuk development lokal, gunakan:
  // final String _baseUrl = 'http://10.0.2.2:8000/api';

  // Timeout untuk request
  static const Duration _timeout = Duration(seconds: 30);

  // Helper method untuk handle response
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        } else if (decoded is List) {
          // Jika response adalah array, wrap dalam object
          return {'data': decoded};
        } else {
          throw Exception('Invalid response format from server');
        }
      } catch (e) {
        throw Exception('Invalid JSON response from server');
      }
    } else {
      try {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic>) {
          final message = responseData['message'] ?? 
                         responseData['error'] ?? 
                         'Request failed with status ${response.statusCode}';
          throw Exception(message);
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } on FormatException {
        // Jika response bukan JSON (misal: halaman error HTML)
        throw Exception('Server error: ${response.statusCode}. Please try again later.');
      }
    }
  }

  // Helper method untuk headers dengan auth
  Map<String, String> _getHeaders({String? token}) {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // Helper method untuk HTTP requests dengan timeout
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFunction,
  ) async {
    try {
      return await requestFunction().timeout(_timeout);
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Request timeout. Please try again.');
      }
      rethrow;
    }
  }

  // --- METHOD OTENTIKASI ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(),
      body: json.encode({
        'email': email,
        'password': password,
      }),
    ));
    
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final url = Uri.parse('$_baseUrl/register');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(),
      body: json.encode({
        'name': name,
        'email': email,
        'password': password,
      }),
    ));
    
    return _handleResponse(response);
  }

  // --- METHOD UNTUK PETA & SCAN ---
  Future<List<Dropbox>> getDropboxes(String token) async {
    final url = Uri.parse('$_baseUrl/dropboxes');
    
    final response = await _makeRequest(() => http.get(
      url,
      headers: _getHeaders(token: token),
    ));
    
    final responseData = _handleResponse(response);
    
    // Handle both direct array response and wrapped response
    List<dynamic> dropboxList;
    if (responseData.containsKey('data') && responseData['data'] is List) {
      dropboxList = responseData['data'] as List<dynamic>;
    } else if (responseData is Map && responseData.containsKey('data')) {
      final data = responseData['data'];
      if (data is List) {
        dropboxList = data;
      } else {
        throw Exception('Invalid dropboxes data format');
      }
    } else {
      throw Exception('Invalid dropboxes response format');
    }
    
    return dropboxList
        .map((item) => Dropbox.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> confirmScan(
    String token, {
    required String dropboxCode,
    required String wasteType,
    required String weight,
  }) async {
    final url = Uri.parse('$_baseUrl/scans/confirm');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode({
        'dropbox_code': dropboxCode,
        'waste_type': wasteType,
        'weight': weight,
      }),
    ));
    
    return _handleResponse(response);
  }

  // --- METHOD UNTUK ECOPAY ---
  Future<Map<String, dynamic>> getWallet(String token) async {
    final url = Uri.parse('$_baseUrl/wallet');
    
    final response = await _makeRequest(() => http.get(
      url,
      headers: _getHeaders(token: token),
    ));
    
    return _handleResponse(response);
  }

  Future<List<Transaction>> getTransactions(String token) async {
    final url = Uri.parse('$_baseUrl/transactions');
    
    final response = await _makeRequest(() => http.get(
      url,
      headers: _getHeaders(token: token),
    ));
    
    final responseData = _handleResponse(response);
    
    // Handle both direct array response and wrapped response
    List<dynamic> transactionList;
    if (responseData.containsKey('data') && responseData['data'] is List) {
      transactionList = responseData['data'] as List<dynamic>;
    } else if (responseData is Map && responseData.containsKey('data')) {
      final data = responseData['data'];
      if (data is List) {
        transactionList = data;
      } else {
        throw Exception('Invalid transactions data format');
      }
    } else {
      throw Exception('Invalid transactions response format');
    }
    
    return transactionList
        .map((item) => Transaction.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> exchangeCoins(String token, int coinsAmount) async {
    final url = Uri.parse('$_baseUrl/coins/exchange');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode({
        'coins_to_exchange': coinsAmount,
      }),
    ));
    
    return _handleResponse(response);
  }

  Future<String> requestTopup(String token, int amount) async {
    final url = Uri.parse('$_baseUrl/topup-request');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode({
        'amount': amount,
      }),
    ));
    
    final responseData = _handleResponse(response);
    return responseData['message'] ?? 'Top up request sent successfully';
  }

  Future<Map<String, dynamic>> transfer(
    String token, {
    required int amount,
    required String destination,
  }) async {
    final url = Uri.parse('$_baseUrl/transfer');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode({
        'amount': amount,
        'destination': destination,
      }),
    ));
    
    return _handleResponse(response);
  }

  // --- METHOD UNTUK LOGOUT ---
  Future<void> logout(String token) async {
    final url = Uri.parse('$_baseUrl/logout');
    
    try {
      final response = await _makeRequest(() => http.post(
        url,
        headers: _getHeaders(token: token),
      ));
      
      _handleResponse(response);
    } catch (e) {
      // Logout gagal di server, tapi tetap logout di local
      // Tidak perlu throw exception
    }
  }

  // --- METHOD UNTUK MENDAPATKAN USER INFO ---
  Future<Map<String, dynamic>> getUserInfo(String token) async {
    final url = Uri.parse('$_baseUrl/user');
    
    final response = await _makeRequest(() => http.get(
      url,
      headers: _getHeaders(token: token),
    ));
    
    return _handleResponse(response);
  }

  // --- METHOD UNTUK TESTING CONNECTION ---
  Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$_baseUrl/dropboxes');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode < 500;
    } catch (e) {
      return false;
    }
  }
}