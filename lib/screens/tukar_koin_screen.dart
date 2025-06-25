import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class TukarKoinScreen extends StatefulWidget {
  const TukarKoinScreen({super.key});

  @override
  State<TukarKoinScreen> createState() => _TukarKoinScreenState();
}

class _TukarKoinScreenState extends State<TukarKoinScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _coinController = TextEditingController();
  
  bool _isLoading = false;
  int _currentCoins = 0;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Exchange rate: 1 coin = Rp 10
  // FIXED: Removed unused coinsPerRupiah field
  static const int minimumExchange = 100; // Minimum 100 coins
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCurrentCoins();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _coinController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentCoins() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      setState(() {
        _currentCoins = authProvider.balanceKoin;
      });
    } catch (e) {
      debugPrint('Error loading coins: $e');
      if (mounted) {
        _showSnackBar('Gagal memuat data koin: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _performExchange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final coinAmount = ConversionUtils.toInt(_coinController.text);
      
      if (coinAmount > _currentCoins) {
        throw Exception('Koin tidak mencukupi untuk ditukar sebanyak $coinAmount');
      }

      debugPrint('🔄 Starting coin exchange process...');
      
      try {
        // FIXED: Use correct parameter name 'coinAmount'
        await _apiService.exchangeCoins(
          token,
          coinAmount: coinAmount,
        );

        debugPrint('✅ Coin exchange successful');
        
        // Refresh user data after successful exchange
        await Future.delayed(const Duration(seconds: 1));
        await authProvider.refreshAllData();
        
        if (mounted) {
          final rupiahAmount = coinAmount * 10; // 1 coin = Rp 10
          
          _showSnackBar(
            'Berhasil menukar $coinAmount koin menjadi ${ConversionUtils.formatCurrency(rupiahAmount)}!',
            isError: false
          );
          
          // Clear the form
          _coinController.clear();
          
          // Refresh coins display
          await _loadCurrentCoins();
          
          // Return success to previous screen
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
        
      } catch (apiError) {
        debugPrint('❌ Coin exchange API error: $apiError');
        
        // Check if it's a server error but exchange might have succeeded
        if (apiError.toString().contains('500') || 
            apiError.toString().contains('502') ||
            apiError.toString().contains('503')) {
          
          // Wait and refresh to check if exchange went through
          await Future.delayed(const Duration(seconds: 2));
          await authProvider.refreshAllData();
          
          if (mounted) {
            _showSnackBar(
              'Penukaran sedang diproses. Silakan cek saldo terbaru di halaman EcoPay.',
              isError: false
            );
            
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.pop(context, true);
              }
            });
          }
        } else {
          // FIXED: Use rethrow instead of throw
          rethrow;
        }
      }
      
    } catch (e) {
      debugPrint('❌ Coin exchange failed: $e');
      if (mounted) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        _showSnackBar('Penukaran gagal: $errorMessage', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  void _setQuickCoinAmount(int amount) {
    _coinController.text = amount.toString();
  }

  int _calculateRupiahFromCoins(int coins) {
    return coins * 10; // 1 coin = Rp 10
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tukar EcoCoins',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF1B5E20),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildCoinsCard(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
                decoration: const BoxDecoration(
                  color: Color(0xFF121212),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: _buildExchangeForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoinsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monetization_on,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EcoCoins Tersedia',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_currentCoins Coins',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Senilai ${ConversionUtils.formatCurrency(_calculateRupiahFromCoins(_currentCoins))}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Add refresh button
          IconButton(
            onPressed: _loadCurrentCoins,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            tooltip: 'Refresh Koin',
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tukar ke Rupiah',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tukar EcoCoins menjadi saldo Rupiah',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            
            // Exchange Rate Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[800]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[400],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nilai Tukar: 1 EcoCoin = Rp 10',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[300],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Minimal penukaran: $minimumExchange EcoCoins',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[200],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Quick Amount Buttons
            const Text(
              'Jumlah EcoCoins',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [100, 500, 1000, 2000].map((amount) => 
                _buildQuickCoinButton(amount)
              ).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Coins Input Field
            TextFormField(
              controller: _coinController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Atau masukkan jumlah custom',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: const Icon(Icons.monetization_on_outlined, color: Colors.grey),
                suffixText: 'Coins',
                suffixStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
              ),
              onChanged: (value) {
                setState(() {}); // Refresh calculated amount
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Jumlah koin harus diisi';
                }
                
                final coins = ConversionUtils.toInt(value);
                if (coins <= 0) {
                  return 'Jumlah koin harus lebih dari 0';
                }
                if (coins > _currentCoins) {
                  return 'Koin tidak mencukupi';
                }
                if (coins < minimumExchange) {
                  return 'Minimal penukaran $minimumExchange EcoCoins';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Calculated Amount Display
            if (_coinController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[800]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Akan diterima:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[300],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ConversionUtils.formatCurrency(
                        _calculateRupiahFromCoins(
                          ConversionUtils.toInt(_coinController.text)
                        )
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green[200],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Exchange Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _performExchange,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey[700],
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Tukar Sekarang',
                        style: TextStyle(
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

  Widget _buildQuickCoinButton(int amount) {
    final isAffordable = amount <= _currentCoins;
    
    return GestureDetector(
      onTap: isAffordable ? () => _setQuickCoinAmount(amount) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isAffordable 
              ? const Color(0xFF2A2A2A) 
              : Colors.grey[800]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isAffordable 
                ? Colors.grey[600]! 
                : Colors.grey[700]!,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$amount Coins',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isAffordable ? Colors.white : Colors.grey[500],
              ),
            ),
            Text(
              ConversionUtils.formatCurrency(_calculateRupiahFromCoins(amount)),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isAffordable ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}