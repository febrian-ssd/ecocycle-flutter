// lib/screens/ecopay_page.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/models/transaction.dart';
import 'package:ecocycle_app/screens/transfer_screen.dart';
import 'package:ecocycle_app/screens/tukar_koin_screen.dart';
import 'package:ecocycle_app/screens/isi_saldo_screen.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';
import 'package:ecocycle_app/utils/auto_refresh_mixin.dart';

class EcoPayPage extends StatefulWidget {
  const EcoPayPage({super.key});

  @override
  State<EcoPayPage> createState() => _EcoPayPageState();
}

class _EcoPayPageState extends State<EcoPayPage> 
    with TickerProviderStateMixin, AutoRefreshMixin {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  double _balanceRp = 0.0;
  int _balanceCoins = 0;
  List<Transaction> _transactions = []; // FIXED: Proper type declaration
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  Duration get refreshInterval => const Duration(seconds: 15);

  @override
  Future<void> onAutoRefresh() async {
    if (!mounted) return;
    
    try {
      debugPrint('🔄 EcoPay auto-refresh triggered');
      await _loadWalletData(showLoading: false);
      await refreshAuthData();
    } catch (e) {
      debugPrint('❌ EcoPay auto-refresh failed: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadWalletData();
    
    // Start auto-refresh after initial load
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        startAutoRefresh();
      }
    });
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
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData({bool showLoading = true}) async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        if (showLoading) {
          setState(() => _isLoading = true);
        }
        
        final walletData = await _apiService.getWallet(token);
        // FIXED: Proper transaction data handling
        final transactions = await _apiService.getTransactions(token);
        
        if (mounted) {
          setState(() {
            _balanceRp = ConversionUtils.toDouble(walletData['balance_rp']);
            _balanceCoins = ConversionUtils.toInt(walletData['balance_coins']);
            // FIXED: Assign List<Transaction> directly
            _transactions = transactions;
            _isLoading = false;
          });
          
          if (showLoading) {
            _fadeController.forward();
            _slideController.forward();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (showLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal memuat data wallet: ${e.toString()}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadWalletData(showLoading: false);
    await refreshAuthData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF4CAF50),
        backgroundColor: const Color(0xFF2A2A2A),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            _isLoading ? _buildLoadingSliver() : _buildContent(),
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
        title: const Text(
          'EcoPay',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
                Color(0xFF4CAF50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 16),
            Text(
              'Memuat data wallet...',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
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
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1A1A1A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EcoCoins Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_balanceCoins',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'EcoCoins',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Color(0xFF4CAF50),
                  size: 28,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF3A3A3A)),
          const SizedBox(height: 16),
          
          // Rupiah Balance Section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Saldo Anda',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3A3A3A)),
            ),
            child: Text(
              ConversionUtils.formatCurrency(_balanceRp),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.add_circle_outline,
            label: 'Top Up',
            color: const Color(0xFF4CAF50),
            onTap: () => _navigateToTopup(),
          ),
          _buildActionButton(
            icon: Icons.send,
            label: 'Transfer',
            color: const Color(0xFF2196F3),
            onTap: () => _navigateToTransfer(),
          ),
          _buildActionButton(
            icon: Icons.swap_horiz,
            label: 'Tukar Koin',
            color: const Color(0xFFFF9800),
            onTap: () => _navigateToTukarKoin(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.8),
                  color,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3A)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Transaksi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Icon(
                  Icons.history,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF3A3A3A), height: 1),
          _transactions.isEmpty
              ? _buildEmptyTransactions()
              : _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.receipt_long,
              size: 48,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada transaksi',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[400],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transaksi Anda akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final recentTransactions = _transactions.take(5).toList();
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentTransactions.length,
      separatorBuilder: (context, index) => 
          const Divider(color: Color(0xFF3A3A3A), height: 1),
      itemBuilder: (context, index) {
        final transaction = recentTransactions[index];
        return _buildTransactionItem(transaction);
      },
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? const Color(0xFF4CAF50) : const Color(0xFFF44336);
    final sign = isIncome ? '+' : '-';
    
    IconData icon;
    switch (transaction.type.toLowerCase()) {
      case 'transfer_in':
        icon = Icons.call_received;
        break;
      case 'transfer_out':
        icon = Icons.call_made;
        break;
      case 'exchange_coins':
        icon = Icons.swap_horiz;
        break;
      case 'scan_reward':
        icon = Icons.qr_code_scanner;
        break;
      case 'topup':
        icon = Icons.add_circle;
        break;
      default:
        icon = Icons.receipt;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        transaction.typeDisplayName,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Colors.white,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transaction.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              transaction.description,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            transaction.formattedDate,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (transaction.amountRp > 0)
            Text(
              '$sign${ConversionUtils.formatCurrency(transaction.amountRp)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          if (transaction.amountCoins > 0) ...[
            const SizedBox(height: 2),
            Text(
              '$sign${transaction.amountCoins} coins',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToTopup() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const IsiSaldoScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
    
    if (result == true) {
      _refreshData();
    }
  }

  void _navigateToTransfer() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const TransferScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
    
    if (result == true) {
      _refreshData();
    }
  }

  void _navigateToTukarKoin() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const TukarKoinScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
    
    if (result == true) {
      _refreshData();
    }
  }
}