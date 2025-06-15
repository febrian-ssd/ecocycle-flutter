// lib/screens/konfirmasi_scan_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/screens/transaksi_berhasil_screen.dart';

class KonfirmasiScanScreen extends StatefulWidget {
  final String qrCodeData;
  const KonfirmasiScanScreen({super.key, required this.qrCodeData});

  @override
  State<KonfirmasiScanScreen> createState() => _KonfirmasiScanScreenState();
}

class _KonfirmasiScanScreenState extends State<KonfirmasiScanScreen> {
  final _wasteTypeController = TextEditingController(text: 'Plastic');
  final _weightController = TextEditingController(text: '12');
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  int _potentialCoins = 0;

  @override
  void initState() {
    super.initState();
    _calculateCoins();
    _weightController.addListener(_calculateCoins);
  }

  @override
  void dispose() {
    _wasteTypeController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _calculateCoins() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    setState(() {
      _potentialCoins = (weight / 10).floor();
    });
  }

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Not authenticated');

      await _apiService.confirmScan(
        token,
        dropboxCode: widget.qrCodeData,
        wasteType: _wasteTypeController.text,
        weight: _weightController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (ctx) => const TransaksiBerhasilScreen()));
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
        title: const Text('Konfirmasi QR Scan', style: TextStyle(color: Colors.white)),
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
                  _buildInfoRow('Dropbox Code', widget.qrCodeData, isEditable: false),
                  _buildInfoRow('Dropbox Location', 'Medan Area (Data Palsu)', isEditable: false),
                  _buildInfoRow('Waste Type', 'Plastic', controller: _wasteTypeController),
                  _buildInfoRow('Weight', '12', controller: _weightController, suffix: 'g'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Anda akan mendapatkan: $_potentialCoins koin',
              style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirm,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                    : const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isEditable = true, String? suffix, TextEditingController? controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16))),
          Expanded(
            flex: 3,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: isEditable ? 4 : 14),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: isEditable
                  ? TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none, suffixText: suffix),
                    )
                  : Text(value, style: const TextStyle(color: Colors.black, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}