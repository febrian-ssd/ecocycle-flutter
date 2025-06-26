// lib/screens/ecopay_page.dart - ALL BALANCE MANAGEMENT FOR LARAVEL
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
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadInitialData();
    
    // Auto refresh every 30 seconds
    _startAutoRefresh();
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

  void _startAutoRefresh() {
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _refreshData(showLoading: false);
        _startAutoRefresh();
      }
    });
  }

  Future<void> _loadInitialData() async {
    await _loadWalletAndTransactions(showLoading: true);
  }

  Future<void> _loadWalletAndTransactions({bool showLoading = true}) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token != null) {
        if (showLoading) {
          setState(() => _isLoading = true);
        }
        
        // Load transactions from Laravel
        final transactions = await _apiService.getTransactions(token);
        
        if (mounted) {
          setState(() {
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
      debugPrint('❌ EcoPay load data failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        if (showLoading) {
          _showSnackBar('Gagal memuat data: ${e.toString()}', isError: true);
        }
      }
    }
  }

  Future<void> _refreshData({bool showLoading = true}) async {
    debugPrint('🔄 EcoPay refreshing data...');
    
    // Refresh AuthProvider data first
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshAllData();
    
    // Then load EcoPay specific data
    await _loadWalletAndTransactions(showLoading: showLoading);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
          'EcoPay Wallet',
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
      actions: [
        Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return IconButton(
              onPressed: auth.isLoading 
                  ? null 
                  : () => _refreshData(showLoading: false),
              icon: auth.isLoading || auth.isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    )
                  : const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
              tooltip: 'Refresh Data',
            );
          },
        ),
      ],
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
                _buildConnectionStatus(),
                const SizedBox(height: 16),
                _buildTransactionHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final balanceRp = authProvider.balanceRp;
        final balanceCoins = authProvider.balanceKoin;
        final isConnected = authProvider.isConnected;
        
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isConnected
                  ? [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)]
                  : [Colors.orange[800]!, Colors.orange[900]!],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isConnected 
                  ? const Color(0xFF4CAF50).withOpacity(0.3)
                  : Colors.orange.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isConnected ? Icons.account_balance_wallet : Icons.warning_amber,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isConnected ? 'Saldo EcoPay' : 'Mode Offline',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isConnected 
                          ? Colors.green.withOpacity(0.2)
                          : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isConnected ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: isConnected ? Colors.green[300] : Colors.orange[300],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Rupiah Balance
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ConversionUtils.formatCurrency(balanceRp),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Saldo Rupiah',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.payments,
                      color: Color(0xFF4CAF50),
                      size: 28,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF3A3A3A)),
              const SizedBox(height: 16),
              
              // EcoCoins Balance
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.eco,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$balanceCoins EcoCoins',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Senilai ${ConversionUtils.formatCurrency(balanceCoins * 10)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Connection warning
              if (!isConnected) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Tidak dapat terhubung ke server Laravel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isConnected = authProvider.isConnected;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transaksi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Top Up',
                      color: const Color(0xFF4CAF50),
                      isEnabled: isConnected,
                      onTap: () => _navigateToTopup(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.send,
                      label: 'Transfer',
                      color: const Color(0xFF2196F3),
                      isEnabled: isConnected,
                      onTap: () => _navigateToTransfer(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.swap_horiz,
                      label: 'Tukar Koin',
                      color: const Color(0xFFFF9800),
                      isEnabled: isConnected,
                      onTap: () => _navigateToTukarKoin(),
                    ),
                  ),
                ],
              ),
              
              if (!isConnected) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[900]?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[700]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_off,
                        color: Colors.orange[300],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fitur transaksi memerlukan koneksi ke server Laravel',
                          style: TextStyle(
                            color: Colors.orange[200],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : () => _showConnectionRequired(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                )
              : LinearGradient(
                  colors: [Colors.grey[800]!, Colors.grey[700]!],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isEnabled ? Colors.white : Colors.grey[500],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.white : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isConnected) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[900]?.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[700]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.orange[300],
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Koneksi Laravel Terputus',
                      style: TextStyle(
                        color: Colors.orange[200],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Beberapa fitur mungkin tidak tersedia. Coba refresh untuk menyambung kembali.',
                      style: TextStyle(
                        color: Colors.orange[300],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => authProvider.retryConnection(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange[200],
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionHistory() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3A3A3A)),
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
            'Transaksi Anda akan muncul di sini setelah melakukan aktivitas',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    final recentTransactions = _transactions.take(10).toList();
    
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
          color: color.withOpacity(0.1),
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

  void _showConnectionRequired() {
    _showSnackBar('Fitur memerlukan koneksi ke server Laravel', isError: true);
  }

  void _navigateToTopup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IsiSaldoScreen()),
    );
    
    if (result == true) {
      _refreshData(showLoading: false);
    }
  }

  void _navigateToTransfer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransferScreen()),
    );
    
    if (result == true) {
      _refreshData(showLoading: false);
    }
  }

  void _navigateToTukarKoin() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TukarKoinScreen()),
    );
    
    if (result == true) {
      _refreshData(showLoading: false);
    }
  }
}