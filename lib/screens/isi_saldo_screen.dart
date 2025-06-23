import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class IsiSaldoScreen extends StatefulWidget {
  const IsiSaldoScreen({super.key}); // FIXED: Added const constructor

  @override
  State<IsiSaldoScreen> createState() => _IsiSaldoScreenState(); // FIXED: Changed state class name
}

class _IsiSaldoScreenState extends State<IsiSaldoScreen> { // FIXED: Changed class name
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  bool _isLoading = false;
  String _selectedMethod = 'bank_transfer';
  
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
  void dispose() {
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
          const SnackBar(
            content: Text('Permintaan top up berhasil dibuat!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat permintaan top up: $e'),
            backgroundColor: Colors.red,
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
          ),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFF2E7D32),
      body: Column(
        children: [
          _buildHeaderCard(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
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
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1), // FIXED: withValues
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)), // FIXED: withValues
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), // FIXED: withValues
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
                color: Colors.black87,
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
                color: Colors.black87,
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
              decoration: InputDecoration(
                labelText: 'Atau masukkan jumlah custom',
                hintText: 'Minimal Rp 10.000',
                prefixIcon: const Icon(Icons.payments_outlined),
                prefixText: 'Rp ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
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
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey[300],
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
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi Penting',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
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
                      color: Colors.orange[800],
                      height: 1.5,
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
          color: isSelected ? const Color(0xFF2E7D32).withValues(alpha: 0.1) : Colors.white, // FIXED: withValues
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF2E7D32) 
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                method['icon'],
                color: isSelected ? Colors.white : Colors.grey[600],
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
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF2E7D32) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2E7D32),
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
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          ConversionUtils.formatCurrency(amount),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}