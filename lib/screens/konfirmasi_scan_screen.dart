// lib/screens/konfirmasi_scan_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/screens/transaksi_berhasil_screen.dart';

class KonfirmasiScanScreen extends StatefulWidget {
  // Sekarang kita menerima string JSON
  final String qrCodeJsonData;
  const KonfirmasiScanScreen({super.key, required this.qrCodeJsonData});

  @override
  State<KonfirmasiScanScreen> createState() => _KonfirmasiScanScreenState();
}

class _KonfirmasiScanScreenState extends State<KonfirmasiScanScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // State untuk menyimpan data yang sudah di-parse dari JSON
  String _dropboxCode = '...';
  String _dropboxLocation = '...';
  String _wasteType = '...';
  double _weight = 0.0;
  int _potentialCoins = 0;

  @override
  void initState() {
    super.initState();
    _parseAndCalculate();
  }

  void _parseAndCalculate() {
    try {
      final data = json.decode(widget.qrCodeJsonData);
      setState(() {
        _dropboxCode = data['id'] ?? 'N/A';
        _dropboxLocation = data['location'] ?? 'N/A';
        _wasteType = data['waste_type'] ?? 'N/A';
        _weight = double.parse(data['weight_g'].toString()); // FIXED: Parse to double
        // Logika 1 gram = 10 koin
        _potentialCoins = (_weight * 10).floor();
      });
    } catch (e) {
      // Jika data bukan JSON, tampilkan sebagai kode saja
      setState(() {
        _dropboxCode = widget.qrCodeJsonData;
        _dropboxLocation = 'Unknown';
        _wasteType = 'Unknown';
        _weight = 0;
        _potentialCoins = 0;
      });
    }
  }

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Not authenticated');

      await _apiService.confirmScan(
        token,
        dropboxCode: _dropboxCode,
        wasteType: _wasteType,
        weight: _weight, // FIXED: Pass as double, not string
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (ctx) => const TransaksiBerhasilScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: AppBar(
        title: const Text('Konfirmasi Scan', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF004d00), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Barcode Information', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  // Semua field sekarang tidak bisa diedit
                  _buildInfoRow('Dropbox Code', _dropboxCode),
                  _buildInfoRow('Dropbox Location', _dropboxLocation),
                  _buildInfoRow('Waste Type', _wasteType),
                  _buildInfoRow('Weight', '${_weight.toStringAsFixed(1)} g'), // FIXED: Better formatting
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Tampilan koin yang akan didapat
            Text(
              'Anda akan mendapatkan: $_potentialCoins koin', // FIXED: Remove unnecessary braces
              style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirm,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Widget ini sekarang hanya untuk menampilkan teks, tidak lagi butuh controller
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16))),
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Text(value, style: const TextStyle(color: Colors.black, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}