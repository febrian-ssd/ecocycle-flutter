// lib/screens/tukar_koin_screen.dart - LENGKAP
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

  @override
  void dispose() {
    _coinController.dispose();
    super.dispose();
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
          SnackBar(
            content: Text('Penukaran gagal: ${e.toString()}'), 
            backgroundColor: Colors.red
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        title: const Text(
          'Tukar Koin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Current Coins Display
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.eco, color: Colors.amber, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Koin Tersedia',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_currentCoins EcoCoins',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Exchange Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jumlah Koin yang Ditukar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _coinController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Masukkan jumlah koin (min. 100)',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      suffixText: 'EcoCoins',
                      suffixStyle: const TextStyle(color: Colors.amber),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Jumlah koin harus diisi';
                      }
                      final amount = ConversionUtils.toInt(value);
                      if (amount < 100) {
                        return 'Minimal tukar 100 koin';
                      }
                      if (amount > _currentCoins) {
                        return 'Koin tidak mencukupi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_coinController.text.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Akan diterima:',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            ConversionUtils.formatCurrency(
                              (ConversionUtils.toInt(_coinController.text) * 10).toDouble()
                            ),
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Exchange Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _performExchange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Tukar Koin Sekarang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[300]),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi Penukaran',
                        style: TextStyle(
                          color: Colors.amber[300],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 1 EcoCoin = Rp 10\n'
                    '• Minimal penukaran 100 koin\n'
                    '• Saldo akan bertambah setelah penukaran berhasil',
                    style: TextStyle(
                      color: Colors.amber[200],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}