// lib/screens/history_page.dart - DIPERBAIKI: Menggunakan metode getHistory tunggal
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _scanHistory = [];
  List<Map<String, dynamic>> _transactionHistory = [];
  Map<String, dynamic> _scanStats = {};
  bool _isLoading = true;
  
  late TabController _tabController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initAnimations();
    _loadData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) throw Exception('User not authenticated');

      // Memuat semua jenis riwayat dari satu endpoint
      final allHistory = await _apiService.getHistory(token);
      
      // Memfilter dan memproses data di sisi klien
      final scans = allHistory.where((item) => item['activity_type'] == 'scan' || item['type'] == 'scan').toList();
      final transactions = allHistory.where((item) => item['activity_type'] == 'transaction' || item['type'] != 'scan').toList();

      int totalScans = scans.length;
      int totalCoinsEarned = scans.fold(0, (sum, item) => sum + ConversionUtils.toInt(item['coins_earned'] ?? 0));
      double totalWasteWeight = scans.fold(0, (sum, item) => sum + ConversionUtils.toDouble(item['weight'] ?? 0));

      if (mounted) {
        setState(() {
          _scanHistory = scans;
          _transactionHistory = transactions;
          _scanStats = {
            'total_scans': totalScans,
            'total_coins_earned': totalCoinsEarned,
            'total_waste_weight': totalWasteWeight,
          };
          _isLoading = false;
        });
        _fadeController.forward(from: 0.0);
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat riwayat: ${e.toString()}'),
            backgroundColor: Colors.red[700],
          ),
        );
      }
    }
  }
  
  // ... (Sisa file UI build-nya tetap sama, tidak perlu diubah) ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Column(
        children: [
          _buildHeader(),
          if (!_isLoading) _buildStatsCards(),
          _buildTabBar(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildTabBarView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromARGB(51, 255, 255, 255),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.history,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Riwayat Aktivitas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildStatCard(
              'Total Scan',
              (_scanStats['total_scans'] ?? 0).toString(),
              Icons.qr_code_scanner,
              const Color(0xFF2196F3),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              'Koin Didapat',
              (_scanStats['total_coins_earned'] ?? 0).toString(),
              Icons.monetization_on,
              const Color(0xFFFF9800),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              'Sampah (kg)',
              ((_scanStats['total_waste_weight'] ?? 0.0) / 1000).toStringAsFixed(1),
              Icons.delete,
              const Color(0xFF4CAF50),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha((255 * 0.3).toInt())),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha((255 * 0.1).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.1).toInt()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: const Color(0xFF4CAF50),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[400],
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: const [
          Tab(
            icon: Icon(Icons.qr_code_scanner, size: 20),
            text: 'Riwayat Scan',
          ),
          Tab(
            icon: Icon(Icons.account_balance_wallet, size: 20),
            text: 'Transaksi',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildScanHistoryTab(),
          _buildTransactionHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildScanHistoryTab() {
    if (_scanHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.qr_code_scanner,
        title: 'Belum Ada Riwayat Scan',
        subtitle: 'Mulai scan sampah untuk melihat riwayat di sini',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scanHistory.length,
      itemBuilder: (context, index) {
        final history = _scanHistory[index];
        return _buildScanHistoryCard(history);
      },
    );
  }

  Widget _buildScanHistoryCard(Map<String, dynamic> history) {
    // ... UI tetap sama
    final isSuccess = (history['status'] ?? 'success') == 'success';
    final wasteType = history['waste_type'] ?? 'plastic';
    final weight = ConversionUtils.toDouble(history['weight'] ?? history['weight_g'] ?? 0);
    final coinsEarned = ConversionUtils.toInt(history['coins_earned'] ?? history['eco_coins'] ?? 0);
    final scanTime = DateTime.tryParse(history['scan_time'] ?? history['created_at'] ?? '');
    final dropboxName = history['dropbox']?['location_name'] ?? 
                       history['dropbox_location'] ?? 
                       history['location'] ?? 
                       'Lokasi Tidak Diketahui';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess ? Colors.green.withAlpha(77) : Colors.red.withAlpha(77),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSuccess 
                        ? Colors.green.withAlpha(26)
                        : Colors.red.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: isSuccess ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSuccess ? 'Scan Berhasil' : 'Scan Gagal',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        scanTime?.toString().substring(0, 16) ?? 'Waktu tidak diketahui',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSuccess && coinsEarned > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+$coinsEarned koin',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.category, 'Jenis Sampah: ${_getWasteTypeName(wasteType)}'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.scale, 'Berat: ${weight.toStringAsFixed(2)} g'),
                  const SizedBox(height: 8),
                  _infoRow(Icons.location_on, 'Lokasi: $dropboxName'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _infoRow(IconData icon, String text) {
      return Row(
          children: [
              Icon(icon, color: Colors.grey[400], size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14))),
          ],
      );
  }


  Widget _buildTransactionHistoryTab() {
    if (_transactionHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.account_balance_wallet,
        title: 'Belum Ada Transaksi',
        subtitle: 'Riwayat transaksi Anda akan muncul di sini',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactionHistory.length,
      itemBuilder: (context, index) {
        return _buildTransactionCard(_transactionHistory[index]);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> transaction) {
    // ... UI tetap sama
    final type = transaction['type'] ?? '';
    final description = transaction['description'] ?? '';
    final amountRp = ConversionUtils.toDouble(transaction['amount_rp']);
    final amountCoins = ConversionUtils.toInt(transaction['amount_coins']);
    final isIncome = amountRp > 0 || amountCoins > 0; // Simplified logic
    final createdAt = DateTime.tryParse(transaction['created_at'] ?? '');
    final typeLabel = transaction['type_label'] ?? _getTypeDisplayName(type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isIncome 
              ? Colors.green.withAlpha(77)
              : Colors.red.withAlpha(77),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isIncome 
                    ? Colors.green.withAlpha(26)
                    : Colors.red.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTransactionIcon(type),
                color: isIncome ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    typeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    createdAt?.toString().substring(0, 16) ?? '',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (amountRp != 0)
                  Text(
                    '${isIncome ? '+' : ''}${ConversionUtils.formatCurrency(amountRp.abs())}',
                    style: TextStyle(
                      color: isIncome ? Colors.green : Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (amountCoins != 0)
                  Text(
                    '${amountCoins >= 0 ? '+' : ''}$amountCoins koin',
                    style: TextStyle(
                      color: amountCoins >= 0 ? Colors.orange : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat riwayat...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getWasteTypeName(String type) {
    const Map<String, String> wasteTypes = {
      'plastic': 'Plastik', 'paper': 'Kertas', 'metal': 'Logam', 'glass': 'Kaca',
    };
    return wasteTypes[type] ?? 'Lainnya';
  }

  String _getTypeDisplayName(String type) {
    const Map<String, String> typeNames = {
      'topup': 'Top Up', 'coin_exchange_to_rp': 'Tukar Koin', 'scan_reward': 'Reward Scan',
      'transfer_out': 'Transfer Keluar', 'transfer_in': 'Transfer Masuk',
    };
    return typeNames[type] ?? type;
  }

  IconData _getTransactionIcon(String type) {
    const Map<String, IconData> icons = {
      'topup': Icons.add_circle, 'coin_exchange_to_rp': Icons.swap_horiz,
      'scan_reward': Icons.qr_code_scanner, 'transfer_out': Icons.arrow_upward,
      'transfer_in': Icons.arrow_downward,
    };
    return icons[type] ?? Icons.circle;
  }
}