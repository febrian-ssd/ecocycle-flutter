// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ecocycle_app/models/dropbox.dart';
import 'package:ecocycle_app/models/transaction.dart';

class ApiService {
  // Pastikan ini adalah domain asli Anda saat online
  final String _baseUrl = 'https://ecocylce.my.id/api';
  // Untuk development lokal, gunakan:
  // final String _baseUrl = 'http://10.0.2.2:8000/api';

  // --- METHOD OTENTIKASI ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/login');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final responseData = json.decode(response.body);
      throw Exception(responseData['message'] ?? 'Login failed.');
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final url = Uri.parse('$_baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {'name': name, 'email': email, 'password': password},
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final responseData = json.decode(response.body);
      throw Exception(responseData['message'] ?? 'Registration failed.');
    }
  }

  // --- METHOD UNTUK PETA & SCAN ---
  Future<List<Dropbox>> getDropboxes(String token) async {
    final url = Uri.parse('$_baseUrl/dropboxes');
    final response = await http.get(url, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Dropbox.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load dropboxes');
    }
  }

  Future<void> confirmScan(String token, {required String dropboxCode, required String wasteType, required String weight}) async {
    final url = Uri.parse('$_baseUrl/scans/confirm');
    final response = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'dropbox_code': dropboxCode,
        'waste_type': wasteType,
        'weight': weight,
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to confirm scan');
    }
  }

  // --- METHOD UNTUK ECOPAY ---
  Future<Map<String, dynamic>> getWallet(String token) async {
    final url = Uri.parse('$_baseUrl/wallet');
    final response = await http.get(url, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load wallet data');
    }
  }

  Future<List<Transaction>> getTransactions(String token) async {
    final url = Uri.parse('$_baseUrl/transactions');
    final response = await http.get(url, headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });
    if (response.statusCode == 200) {
      List<dynamic> body = json.decode(response.body);
      return body.map((dynamic item) => Transaction.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<void> exchangeCoins(String token, int coinsAmount) async {
    final url = Uri.parse('$_baseUrl/coins/exchange');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: {'coins_to_exchange': coinsAmount.toString()},
    );
    if (response.statusCode != 200) {
      final responseData = json.decode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to exchange coins');
    }
  }
  
  Future<void> topup(String token, int amount) async {
    final url = Uri.parse('$_baseUrl/topup');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: {'amount': amount.toString()},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to top up balance');
    }
  }

  Future<void> transfer(String token, {required int amount, required String destination}) async {
    final url = Uri.parse('$_baseUrl/transfer');
    final response = await http.post(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: {'amount': amount.toString(), 'destination': destination},
    );
    if (response.statusCode != 200) {
      final responseData = json.decode(response.body);
      throw Exception(responseData['message'] ?? 'Failed to transfer');
    }
  }
}