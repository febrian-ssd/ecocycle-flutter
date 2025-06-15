// lib/screens/transfer_screen.dart
import 'package:flutter/material.dart';
import 'transaksi_berhasil_screen.dart';

class TransferScreen extends StatelessWidget {
  const TransferScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: AppBar(
        title: const Text('Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            _buildTextField('Masukan Nomor Rekening/akun e-Wallet', TextInputType.text),
            const SizedBox(height: 20),
            _buildTextField('Masukan Nominal', TextInputType.number),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showSuccess(context),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Confirm', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextInputType keyboardType) {
    return TextField(
      style: const TextStyle(color: Colors.black87, fontSize: 16), keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Colors.grey),
        filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
  void _showSuccess(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const TransaksiBerhasilScreen()));
  }
}