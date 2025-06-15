// lib/screens/isi_saldo_screen.dart

import 'package:flutter/material.dart';
import 'transaksi_berhasil_screen.dart';

class IsiSaldoScreen extends StatefulWidget {
  const IsiSaldoScreen({super.key});

  @override
  State<IsiSaldoScreen> createState() => _IsiSaldoScreenState();
}

class _IsiSaldoScreenState extends State<IsiSaldoScreen> {
  // State untuk menyimpan metode pembayaran yang dipilih
  String? _selectedMethod;

  // Fungsi yang dipanggil saat tombol Confirm ditekan
  void _confirmAction() {
    // PERBAIKAN LOGIKA: Cek apakah metode sudah dipilih
    if (_selectedMethod == null) {
      // Jika belum, tampilkan pesan error dan jangan lanjutkan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih metode pembayaran terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Jika sudah dipilih, lanjutkan ke halaman sukses
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (ctx) => const TransaksiBerhasilScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: AppBar(
        title: const Text('Isi Saldo',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 32)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukan Nominal',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            _buildTextField(),
            const SizedBox(height: 24),
            const Text('Metode Pembayaran',
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            _buildPaymentMethod('Indomaret'),
            _buildPaymentMethod('Alfamart'),
            _buildPaymentMethod('Bank'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _confirmAction, // Panggil fungsi yang sudah ada logikanya
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Confirm',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      style: const TextStyle(color: Colors.black87, fontSize: 18),
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12))),
        prefixText: 'Rp. ',
        prefixStyle: TextStyle(color: Colors.black87, fontSize: 18),
      ),
    );
  }
  
  Widget _buildPaymentMethod(String method) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: RadioListTile<String>(
        title: Text(method, style: const TextStyle(color: Colors.white)),
        value: method,
        groupValue: _selectedMethod,
        onChanged: (String? value) {
          setState(() {
            _selectedMethod = value;
          });
        },
        activeColor: Colors.orange,
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}