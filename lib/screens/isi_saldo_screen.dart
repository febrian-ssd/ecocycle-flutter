// lib/screens/isi_saldo_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'transaksi_berhasil_screen.dart';

class IsiSaldoScreen extends StatefulWidget {
  const IsiSaldoScreen({super.key});
  @override
  State<IsiSaldoScreen> createState() => _IsiSaldoScreenState();
}

class _IsiSaldoScreenState extends State<IsiSaldoScreen> {
  final _amountController = TextEditingController();
  final ApiService _apiService = ApiService();
  String? _selectedMethod;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _confirmTopUp() async {
    if (_amountController.text.isEmpty || _selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Silakan isi nominal dan pilih metode pembayaran.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('User not authenticated.');

      final amount = int.parse(_amountController.text);
      await _apiService.topup(token, amount);

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (ctx) => const TransaksiBerhasilScreen()));
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
        title: const Text('Isi Saldo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukan Nominal', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              style: const TextStyle(color: Colors.black87, fontSize: 18),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                prefixText: 'Rp. ', prefixStyle: TextStyle(color: Colors.black87, fontSize: 18),
              )
            ),
            const SizedBox(height: 24),
            const Text('Metode Pembayaran', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            _buildPaymentMethod('Indomaret'),
            _buildPaymentMethod('Alfamart'),
            _buildPaymentMethod('Bank'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmTopUp,
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

  Widget _buildPaymentMethod(String method) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.grey[800],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: RadioListTile<String>(
        title: Text(method, style: const TextStyle(color: Colors.white)),
        value: method, groupValue: _selectedMethod,
        onChanged: (String? value) { setState(() { _selectedMethod = value; }); },
        activeColor: Colors.orange, controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }
}