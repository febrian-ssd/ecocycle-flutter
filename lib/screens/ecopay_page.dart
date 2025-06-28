// lib/screens/ecopay_page.dart - Desain Elegan dengan Navigasi yang Benar
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/models/transaction.dart';
import 'package:ecocycle_app/screens/transfer_screen.dart';
import 'package:ecocycle_app/screens/tukar_koin_screen.dart';
import 'package:ecocycle_app/screens/isi_saldo_screen.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class EcoPayPage extends StatefulWidget {
  const EcoPayPage({super.key});

  @override
  State<EcoPayPage> createState() => _EcoPayPageState();
}

class _EcoPayPageState extends State<EcoPayPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Transaction> _transactions = [];

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadInitialData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await _refreshData(showLoading: true);
  }

  Future<void> _refreshData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshAllData(); // Refresh data saldo dan koin dari provider

      final token = authProvider.token;
      if (token != null) {
        final transactions = await _apiService.getTransactions(token);
        if (mounted) {
          setState(() {
            _transactions = transactions;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Gagal memuat data EcoPay: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _fadeController.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: RefreshIndicator(
        onRefresh: () => _refreshData(showLoading: false),
        color: const Color(0xFF4CAF50),
        backgroundColor: const Color(0xFF2A2A2A),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                    ),
                  )
                : _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color(0xFF1B5E20),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text('EcoPay Wallet',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildWalletCard(),
              const SizedBox(height: 24),
              _buildActionButtons(),
              const SizedBox(height: 24),
              _buildTransactionHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Text('Saldo Anda', style: TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                ConversionUtils.formatCurrency(authProvider.balanceRp),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Divider(color: Colors.white24, height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.eco, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '${authProvider.balanceKoin} EcoCoins',
                    style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _actionButton(
          label: 'Isi Saldo',
          icon: Icons.add_circle_outline,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const IsiSaldoScreen())).then((_) => _refreshData()),
        ),
        _actionButton(
          label: 'Transfer',
          icon: Icons.send,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TransferScreen())).then((_) => _refreshData()),
        ),
        _actionButton(
          label: 'Tukar Koin',
          icon: Icons.swap_horiz,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TukarKoinScreen())).then((_) => _refreshData()),
        ),
      ],
    );
  }

  Widget _actionButton({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Icon(icon, color: const Color(0xFF4CAF50), size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Transaksi',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _transactions.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'Belum ada transaksi.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  final isIncome = transaction.isIncome;
                  final color = isIncome ? Colors.greenAccent : Colors.redAccent;
                  
                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: color,
                      ),
                      title: Text(
                        transaction.typeDisplayName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        transaction.description.isNotEmpty ? transaction.description : transaction.formattedDate,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        transaction.amountRp != 0
                            ? '${isIncome ? '+' : '-'} ${ConversionUtils.formatCurrency(transaction.amountRp)}'
                            : '${isIncome ? '+' : '-'} ${transaction.amountCoins} Koin',
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }
}