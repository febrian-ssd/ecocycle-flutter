import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ecocycle_app/models/transaction.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.1.100:8000/api';

  // Headers dengan Content-Type JSON
  Map<String, String> _getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Wrapper untuk request dengan error handling
  Future<http.Response> _makeRequest(Future<http.Response> Function() request) async {
    try {
      return await request();
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } on HttpException {
      throw Exception('Gagal terhubung ke server');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Handle response dengan error checking
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseData = json.decode(response.body);
      return responseData is Map<String, dynamic> ? responseData : {'data': responseData};
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Terjadi kesalahan server');
    }
  }

  // AUTH ENDPOINTS
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
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

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
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

  Future<void> logout(String token) async {
    final url = Uri.parse('$_baseUrl/logout');
    
    await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
    ));
  }

  // USER PROFILE
  Future<Map<String, dynamic>> getProfile(String token) async {
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
    final url = Uri.parse('$_baseUrl/scan/confirm');
    
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

  // HISTORY ENDPOINTS
  Future<List<Map<String, dynamic>>> getHistory(String token) async {
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
    final url = Uri.parse('$_baseUrl/wallet');
    
    final response = await _makeRequest(() => http.get(
      url,
      headers: _getHeaders(token: token),
    ));
    
    final responseData = _handleResponse(response);
    
    // Safe conversion using ConversionUtils
    return {
      'balance_rp': ConversionUtils.toDouble(responseData['balance_rp']),
      'balance_coins': ConversionUtils.toInt(responseData['balance_coins']),
      'formatted_balance_rp': responseData['formatted_balance_rp'] ?? 'Rp 0',
    };
  }

  Future<List<Transaction>> getTransactions(String token) async {
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
    final url = Uri.parse('$_baseUrl/transfer');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode({
        'email': email,
        'amount': amount,
        'description': description ?? '',
      }),
    ));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> exchangeCoins(String token, {
    required int coins,
  }) async {
    final url = Uri.parse('$_baseUrl/exchange-coins');
    
    final response = await _makeRequest(() => http.post(
      url,
      headers: _getHeaders(token: token),
      body: json.encode({
        'coins': coins,
      }),
    ));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> topupRequest(String token, {
    required double amount,
    required String method,
  }) async {
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
    final url = Uri.parse('$_baseUrl/topup-requests');
    
    final response = await _makeRequest(() => http.get(
      url,
      headers: _getHeaders(token: token),
    ));

    final responseData = _handleResponse(response);
    final requests = responseData['data'] as List? ?? responseData as List? ?? [];
    
    return requests.cast<Map<String, dynamic>>();
  }

  // UPLOAD PAYMENT PROOF
  Future<Map<String, dynamic>> uploadPaymentProof(
    String token, 
    int topupRequestId, 
    File imageFile
  ) async {
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