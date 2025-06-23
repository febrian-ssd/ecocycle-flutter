// lib/screens/isi_saldo_screen.dart - Dark Elegant Theme
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class IsiSaldoScreen extends StatefulWidget {
  const IsiSaldoScreen({super.key});

  @override
  State<IsiSaldoScreen> createState() => _IsiSaldoScreenState();
}

class _IsiSaldoScreenState extends State<IsiSaldoScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedMethod = 'bank_transfer';
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<Map<String, dynamic>> _topupMethods = [
    {
      'id': 'bank_transfer',
      'name': 'Transfer Bank',
      'icon': Icons.account_balance,
      'description': 'Transfer melalui rekening bank',
      'min_amount': 10000,
    },
    {
      'id': 'e_wallet',
      'name': 'E-Wallet',
      'icon': Icons.account_balance_wallet,
      'description': 'OVO, GoPay, DANA, ShopeePay',
      'min_amount': 10000,
    },
    {
      'id': 'virtual_account',
      'name': 'Virtual Account',
      'icon': Icons.credit_card,
      'description': 'BCA, Mandiri, BNI, BRI',
      'min_amount': 10000,
    },
  ];

  final List<int> _quickAmounts = [50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitTopupRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final amount = ConversionUtils.toDouble(_amountController.text);

      await _apiService.topupRequest(
        token,
        amount: amount,
        method: _selectedMethod,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Permintaan top up berhasil dibuat!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuat permintaan top up: $errorMessage',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setQuickAmount(int amount) {
    _amountController.text = amount.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Top Up Saldo',
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
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              _buildHeaderCard(),
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
                  child: _buildTopupForm(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
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
              Icons.add_circle,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Up Saldo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Isi saldo untuk transaksi di EcoCycle',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopupForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Payment Methods
            ..._topupMethods.map((method) => _buildPaymentMethodCard(method)),
            
            const SizedBox(height: 24),
            
            // Amount Section
            const Text(
              'Jumlah Top Up',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Quick Amount Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _quickAmounts.map((amount) => 
                _buildQuickAmountButton(amount)
              ).toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Custom Amount Input
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Atau masukkan jumlah custom',
                labelStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'Minimal Rp 10.000',
                hintStyle: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: const Icon(Icons.payments_outlined, color: Colors.grey),
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah top up harus diisi';
                }
                
                final amount = ConversionUtils.toDouble(value);
                if (amount <= 0) {
                  return 'Jumlah top up harus lebih dari 0';
                }
                if (amount < 10000) {
                  return 'Minimal top up Rp 10.000';
                }
                if (amount > 10000000) {
                  return 'Maksimal top up Rp 10.000.000';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitTopupRequest,
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
                        'Buat Permintaan Top Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[800]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[400],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi Penting',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[300],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Permintaan top up akan diproses dalam 1x24 jam\n'
                    '• Anda akan mendapat notifikasi setelah saldo masuk\n'
                    '• Pastikan melakukan pembayaran sesuai instruksi\n'
                    '• Hubungi customer service jika ada kendala',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange[200],
                      height: 1.5,
                      fontWeight: FontWeight.w600,
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

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedMethod == method['id'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method['id'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50).withValues(alpha: 0.15) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF4CAF50) 
                    : Colors.grey[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                method['icon'],
                color: isSelected ? Colors.white : Colors.grey[400],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF4CAF50) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountButton(int amount) {
    return GestureDetector(
      onTap: () => _setQuickAmount(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[600]!),
        ),
        child: Text(
          ConversionUtils.formatCurrency(amount),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}