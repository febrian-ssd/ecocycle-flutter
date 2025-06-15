// lib/screens/scan_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ecocycle_app/screens/konfirmasi_scan_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _isScanCompleted = false;

  void _handleDetection(String code) {
    if (!_isScanCompleted) {
      setState(() {
        _isScanCompleted = true;
      });
      // Pindah ke halaman konfirmasi dan kirim data hasil scan
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => KonfirmasiScanScreen(qrCodeData: code),
        ),
      ).then((_) {
        // Reset status saat kembali ke halaman ini
        if (mounted) {
          setState(() {
            _isScanCompleted = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Dropbox', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (capture.barcodes.isNotEmpty) {
                final String code = capture.barcodes.first.rawValue ?? "Error";
                _handleDetection(code);
              }
            },
          ),
          // UI overlay untuk bingkai scan
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 4),
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          // === TOMBOL SIMULASI UNTUK DEVELOPMENT ===
          Positioned(
            bottom: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                // Pura-pura berhasil scan kode "db0001"
                _handleDetection('db0001');
              },
              icon: const Icon(Icons.camera),
              label: const Text('Simulasi Scan Berhasil'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          )
        ],
      ),
    );
  }
}