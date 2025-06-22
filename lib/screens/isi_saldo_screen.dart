// lib/screens/isi_saldo_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:intl/intl.dart';

class IsiSaldoScreen extends StatefulWidget {
  const IsiSaldoScreen({super.key});
  @override
  State<IsiSaldoScreen> createState() => _IsiSaldoScreenState();
}
class _IsiSaldoScreenState extends State<IsiSaldoScreen> {
  int? _selectedAmount;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _confirmRequest() async {
    if (_selectedAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Silakan pilih nominal top up.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final message = await _apiService.requestTopup(token, _selectedAmount!);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Berhasil'),
            content: Text(message),
            actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))],
          ),
        ).then((_) => Navigator.of(context).pop());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(e.toString())));
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Nominal Top Up', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            _buildAmountOption(10000),
            _buildAmountOption(25000),
            _buildAmountOption(50000),
            _buildAmountOption(100000),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Konfirmasi Top Up', style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountOption(int amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: _selectedAmount == amount ? Colors.green[700] : Colors.grey[800],
      child: RadioListTile<int>(
        title: Text(formatter.format(amount), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        value: amount,
        groupValue: _selectedAmount,
        onChanged: (int? value) { setState(() { _selectedAmount = value; }); },
        activeColor: Colors.orange,
      ),
    );
  }
}