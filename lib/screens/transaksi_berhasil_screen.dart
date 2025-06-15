// lib/screens/transaksi_berhasil_screen.dart

import 'package:flutter/material.dart';

class TransaksiBerhasilScreen extends StatelessWidget {
  // === PERUBAHAN UTAMA ADA DI BARIS INI: TAMBAHKAN 'const' ===
  const TransaksiBerhasilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 24),
            const Text('Transaksi Berhasil', style: TextStyle(color: Colors.white, fontSize: 24)),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                // Gunakan pop untuk kembali ke halaman sebelumnya
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Kembali', style: TextStyle(color: Colors.white, fontSize: 18)),
            )
          ],
        ),
      ),
    );
  }
}