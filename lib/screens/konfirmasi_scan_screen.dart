import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/screens/transaksi_berhasil_screen.dart';

class KonfirmasiScanScreen extends StatefulWidget {
  final String qrCodeJsonData;
  const KonfirmasiScanScreen({super.key, required this.qrCodeJsonData});

  @override
  State<KonfirmasiScanScreen> createState() => _KonfirmasiScanScreenState();
}

class _KonfirmasiScanScreenState extends State<KonfirmasiScanScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  String _dropboxCode = 'Unknown';
  String _dropboxLocation = 'Unknown Location';
  String _wasteType = 'Unknown';
  double _weight = 0.0;
  int _potentialCoins = 0;
  bool _isValidQR = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _parseAndCalculate();
  }

  void _parseAndCalculate() {
    try {
      debugPrint('📱 Raw QR Data: ${widget.qrCodeJsonData}');
      
      // Coba parse sebagai JSON
      Map<String, dynamic> data;
      
      try {
        data = json.decode(widget.qrCodeJsonData);
        debugPrint('✅ JSON parsed successfully: $data');
      } catch (e) {
        debugPrint('❌ JSON parse failed: $e');
        // Jika bukan JSON, mungkin URL atau text biasa
        setState(() {
          _errorMessage = 'QR Code bukan format dropbox yang valid. Pastikan QR code berisi data JSON dropbox.';
          _isValidQR = false;
        });
        return;
      }
      
      // Validasi field yang dibutuhkan
      if (!data.containsKey('id') || !data.containsKey('location') || 
          !data.containsKey('waste_type') || !data.containsKey('weight_g')) {
        setState(() {
          _errorMessage = 'QR Code tidak lengkap. Diperlukan: id, location, waste_type, weight_g';
          _isValidQR = false;
        });
        return;
      }
      
      setState(() {
        _dropboxCode = data['id']?.toString() ?? 'Unknown';
        _dropboxLocation = data['location']?.toString() ?? 'Unknown Location';
        _wasteType = data['waste_type']?.toString() ?? 'Unknown';
        _weight = _parseWeight(data['weight_g']);
        _potentialCoins = (_weight * 10).floor();
        _isValidQR = true;
        _errorMessage = '';
      });
      
      debugPrint('✅ Parsed data:');
      debugPrint('  - ID: $_dropboxCode');
      debugPrint('  - Location: $_dropboxLocation');
      debugPrint('  - Waste Type: $_wasteType');
      debugPrint('  - Weight: $_weight g');
      debugPrint('  - Potential Coins: $_potentialCoins');
      
    } catch (e) {
      debugPrint('❌ Parse error: $e');
      setState(() {
        _errorMessage = 'Gagal membaca QR Code: ${e.toString()}';
        _isValidQR = false;
      });
    }
  }

  double _parseWeight(dynamic weightValue) {
    if (weightValue == null) return 0.0;
    if (weightValue is num) return weightValue.toDouble();
    if (weightValue is String) {
      return double.tryParse(weightValue) ?? 0.0;
    }
    return 0.0;
  }

  String _getWasteTypeDisplayName(String type) {
    const Map<String, String> wasteTypes = {
      'plastic': 'Plastik',
      'paper': 'Kertas', 
      'metal': 'Logam',
      'glass': 'Kaca',
    };
    return wasteTypes[type.toLowerCase()] ?? type;
  }

  Future<void> _confirm() async {
    if (!_isValidQR) {
      _showErrorSnackBar('QR Code tidak valid, tidak dapat melanjutkan');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('Tidak terautentikasi. Silakan login ulang.');

      debugPrint('🔄 Sending scan confirmation to API...');
      debugPrint('  - Token: ${token.substring(0, 20)}...');
      debugPrint('  - Dropbox Code: $_dropboxCode');
      debugPrint('  - Waste Type: $_wasteType');
      debugPrint('  - Weight: $_weight');

      await _apiService.confirmScan(
        token,
        dropboxCode: _dropboxCode,
        wasteType: _wasteType,
        weight: _weight,
      );

      debugPrint('✅ Scan confirmation successful');

      // Refresh user data untuk update koin
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshAllData();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (ctx) => ScanBerhasilScreen(
              coins: _potentialCoins,
              location: _dropboxLocation,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Scan confirmation failed: $e');
      if (mounted) {
        _showErrorSnackBar('Konfirmasi scan gagal: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Konfirmasi Scan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Error message jika QR tidak valid
            if (!_isValidQR) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 12),
                        const Text(
                          'QR Code Tidak Valid',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Format QR yang benar:\n{"id":"DBX001","location":"Nama Lokasi","waste_type":"plastic","weight_g":150}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Informasi dropbox jika QR valid
            if (_isValidQR) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Dropbox',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInfoRow('ID Dropbox', _dropboxCode),
                    _buildInfoRow('Lokasi', _dropboxLocation),
                    _buildInfoRow('Jenis Sampah', _getWasteTypeDisplayName(_wasteType)),
                    _buildInfoRow('Berat', '${_weight.toStringAsFixed(1)} gram'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Reward info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.eco, color: Colors.amber, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reward yang akan diterima:',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          Text(
                            '$_potentialCoins EcoCoins',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Tombol konfirmasi
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || !_isValidQR) ? null : _confirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isValidQR ? const Color(0xFF4CAF50) : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        _isValidQR ? 'Konfirmasi Scan' : 'QR Code Tidak Valid',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}