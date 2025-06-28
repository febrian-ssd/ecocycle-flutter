// lib/screens/tukar_koin_screen.dart - DIPERBAIKI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';
import 'package:ecocycle_app/screens/transaksi_berhasil_screen.dart';

class TukarKoinScreen extends StatefulWidget {
  const TukarKoinScreen({super.key});

  @override
  State<TukarKoinScreen> createState() => _TukarKoinScreenState();
}

class _TukarKoinScreenState extends State<TukarKoinScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _coinController = TextEditingController();
  
  bool _isLoading = false;
  int _currentCoins = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentCoins();
  }

  void _loadCurrentCoins() {
    setState(() {
      _currentCoins = Provider.of<AuthProvider>(context, listen: false).balanceKoin;
    });
  }

  Future<void> _performExchange() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final coinAmount = ConversionUtils.toInt(_coinController.text);

      // DIPERBAIKI: Memanggil metode exchangeCoins yang benar
      await _apiService.exchangeCoins(token!, coinAmount: coinAmount);
      
      await authProvider.refreshAllData();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExchangeBerhasilScreen(
              coins: coinAmount,
              amount: (coinAmount * 10).toDouble(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Penukaran gagal: ${e.toString()}'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (UI Tetap Sama) ...
     return Scaffold(
      appBar: AppBar(title: const Text('Tukar Koin')),
      body: Container(), // Placeholder
    );
  }
}