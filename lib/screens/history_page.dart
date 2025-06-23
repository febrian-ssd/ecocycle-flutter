// lib/screens/history_page.dart - Real Scan Data
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _scanHistory = [];
  bool _isLoading = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    
    _loadScanHistory();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadScanHistory() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        final history = await _apiService.getHistory(token);
        
        if (mounted) {
          setState(() {
            _scanHistory = history;
            _isLoading = false;
          });
          _fadeController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memuat riwayat: $e',
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

  Future<void> _refreshHistory() async {
    setState(() => _isLoading = true);
    await _loadScanHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        color: const Color(0xFF4CAF50),
        backgroundColor: const Color(0xFF2A2A2A),
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            _isLoading ? _buildLoadingSliver() : _buildHistoryList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: const Color(0xFF1B5E20),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          'Riwayat Scan',
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
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total ${_scanHistory.length} aktivitas',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
              'Memuat riwayat...',
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

  Widget _buildHistoryList() {
    if (_scanHistory.isEmpty) {
      return _buildEmptyState();
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: FadeTransition(
        opacity: _fadeAnimation,
        child: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final historyItem = _scanHistory[index];
              return _buildHistoryCard(historyItem, index);
            },
            childCount: _scanHistory.length,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.eco_outlined,
                  size: 64,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Belum Ada Riwayat Scan',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mulai scan dropbox untuk melihat\nriwayat aktivitas Anda di sini',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to scan screen
                  Navigator.of(context).pop(); // Go back to home
                  // Trigger scan from home (index 2)
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text(
                  'Mulai Scan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, int index) {
    // Parse data from API response
    final String dropboxLocation = item['dropbox_location'] ?? item['location'] ?? 'Lokasi Tidak Diketahui';
    final String dropboxAddress = item['dropbox_address'] ?? item['address'] ?? '';
    final String wasteType = item['waste_type'] ?? 'Unknown';
    final double weight = (item['weight'] ?? item['weight_g'] ?? 0.0) is String 
        ? double.tryParse(item['weight'].toString()) ?? 0.0 
        : (item['weight'] ?? item['weight_g'] ?? 0.0).toDouble();
    final int coinsEarned = item['coins_earned'] ?? item['coins'] ?? 0;
    final String scanTime = item['scan_time'] ?? item['created_at'] ?? DateTime.now().toIso8601String();
    
    // Parse scan time
    DateTime? scanDate;
    try {
      scanDate = DateTime.parse(scanTime);
    } catch (e) {
      scanDate = DateTime.now();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getWasteTypeColor(wasteType).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with location and time
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getWasteTypeColor(wasteType).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getWasteTypeIcon(wasteType),
                        color: _getWasteTypeColor(wasteType),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dropboxLocation,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (dropboxAddress.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              dropboxAddress,
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Text(
                      _formatTimeAgo(scanDate),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Waste details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Jenis Sampah',
                          _formatWasteType(wasteType),
                          Icons.category,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[700],
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          'Berat',
                          '${weight.toStringAsFixed(0)}g',
                          Icons.scale,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[700],
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          'EcoCoins',
                          '$coinsEarned',
                          Icons.eco,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF4CAF50),
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getWasteTypeColor(String wasteType) {
    switch (wasteType.toLowerCase()) {
      case 'plastic':
        return Colors.orange;
      case 'paper':
        return Colors.brown;
      case 'metal':
        return Colors.grey;
      case 'glass':
        return Colors.blue;
      default:
        return const Color(0xFF4CAF50);
    }
  }

  IconData _getWasteTypeIcon(String wasteType) {
    switch (wasteType.toLowerCase()) {
      case 'plastic':
        return Icons.local_drink;
      case 'paper':
        return Icons.description;
      case 'metal':
        return Icons.build;
      case 'glass':
        return Icons.wine_bar;
      default:
        return Icons.recycling;
    }
  }

  String _formatWasteType(String wasteType) {
    switch (wasteType.toLowerCase()) {
      case 'plastic':
        return 'Plastik';
      case 'paper':
        return 'Kertas';
      case 'metal':
        return 'Logam';
      case 'glass':
        return 'Kaca';
      default:
        return wasteType;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}h lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}j lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m lalu';
    } else {
      return 'Baru saja';
    }
  }
}