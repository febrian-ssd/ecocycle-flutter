// lib/screens/transfer_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'transaksi_berhasil_screen.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});
  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _destinationController = TextEditingController();
  final _amountController = TextEditingController();
  final ApiService _apiService = ApiService(); // <-- Deklarasi yang hilang
  bool _isLoading = false;

  @override
  void dispose() {
    _destinationController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirmTransfer() async {
    if (_destinationController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Semua field harus diisi.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('User not authenticated.');

      final amount = int.parse(_amountController.text);
      await _apiService.transfer(token, amount: amount, destination: _destinationController.text);

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const TransaksiBerhasilScreen()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(e.toString().replaceFirst("Exception: ", ""))),
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
        title: const Text('Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 30),
            _buildTextField('Masukan Nomor Rekening/akun e-Wallet', TextInputType.text, _destinationController),
            const SizedBox(height: 20),
            _buildTextField('Masukan Nominal', TextInputType.number, _amountController),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmTransfer,
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

  Widget _buildTextField(String label, TextInputType keyboardType, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.black87, fontSize: 16), keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: label, hintStyle: const TextStyle(color: Colors.grey),
        filled: true, fillColor: Colors.white, border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
    );
  }
}