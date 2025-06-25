// lib/screens/home_screen.dart - IMPROVED VERSION WITH GRACEFUL ERROR HANDLING
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/widgets/wallet_error_widget.dart';
import 'package:ecocycle_app/screens/isi_saldo_screen.dart';
import 'package:ecocycle_app/screens/transfer_screen.dart';
import 'package:ecocycle_app/screens/tukar_koin_screen.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _refreshData();
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
    super.dispose();
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.refreshAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF4CAF50),
        backgroundColor: const Color(0xFF2A2A2A),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(),
                  
                  // Wallet error banner (compact version)
                  const WalletErrorBanner(),
                  
                  _buildWalletCard(),
                  _buildQuickActions(),
                  _buildFeatureGrid(),
                  _buildRecentActivity(),
                  const SizedBox(height: 100), // Bottom padding for navigation
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final userName = user?['name'] ?? user?['full_name'] ?? 'Pengguna';
        
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat datang,',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showNotifications(context),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalletCard() {
    return const WalletBalanceCard(showRefreshButton: true);
  }

  Widget _buildQuickActions() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aksi Cepat',
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
                    child: _buildQuickActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Top Up',
                      onTap: () => _navigateToTopUp(context),
                      isEnabled: true, // Always enabled
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.send_outlined,
                      label: 'Transfer',
                      onTap: () => _navigateToTransfer(context),
                      isEnabled: !authProvider.hasWalletError,
                      disabledReason: authProvider.hasWalletError 
                          ? 'Fitur tidak tersedia' 
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionButton(
                      icon: Icons.swap_horiz,
                      label: 'Tukar Koin',
                      onTap: () => _navigateToExchange(context),
                      isEnabled: !authProvider.hasWalletError,
                      disabledReason: authProvider.hasWalletError 
                          ? 'Fitur tidak tersedia' 
                          : null,
                    ),
                  ),
                ],
              ),
              
              // Show wallet error info if needed
              if (authProvider.hasWalletError) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[900]?.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[700]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[300],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Beberapa fitur wallet sedang dalam pengembangan',
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

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    required bool isEnabled,
    String? disabledReason,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : () => _showFeatureUnavailable(disabledReason),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled 
              ? const Color(0xFF2A2A2A) 
              : Colors.grey[800]?.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled 
                ? Colors.grey[700]! 
                : Colors.grey[600]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isEnabled ? const Color(0xFF4CAF50) : Colors.grey[500],
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isEnabled ? Colors.white : Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fitur Utama',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildFeatureCard(
                icon: Icons.recycling,
                title: 'Setor Sampah',
                subtitle: 'Dapatkan EcoCoins',
                color: Colors.green,
                onTap: () => _navigateToWasteDeposit(context),
              ),
              _buildFeatureCard(
                icon: Icons.location_on,
                title: 'Lokasi Dropbox',
                subtitle: 'Cari terdekat',
                color: Colors.blue,
                onTap: () => _navigateToDropboxMap(context),
              ),
              _buildFeatureCard(
                icon: Icons.history,
                title: 'Riwayat',
                subtitle: 'Lihat transaksi',
                color: Colors.purple,
                onTap: () => _navigateToHistory(context),
              ),
              _buildFeatureCard(
                icon: Icons.eco,
                title: 'EcoChallenge',
                subtitle: 'Tantangan hijau',
                color: Colors.orange,
                onTap: () => _navigateToChallenge(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktivitas Terbaru',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToHistory(context),
                child: Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Placeholder for recent activities
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.hasWalletError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[500],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Riwayat aktivitas akan ditampilkan setelah layanan tersedia',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: [
                  _buildActivityItem(
                    icon: Icons.recycling,
                    title: 'Setor Sampah Plastik',
                    subtitle: '2 kg • +20 EcoCoins',
                    time: '2 jam lalu',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildActivityItem(
                    icon: Icons.send,
                    title: 'Transfer ke John Doe',
                    subtitle: 'Rp 50.000',
                    time: '1 hari lalu',
                    color: Colors.blue,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Navigation methods
  void _navigateToTopUp(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IsiSaldoScreen()),
    );
    
    if (result == true && mounted) {
      await _refreshData();
    }
  }

  void _navigateToTransfer(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransferScreen()),
    );
    
    if (result == true && mounted) {
      await _refreshData();
    }
  }

  void _navigateToExchange(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TukarKoinScreen()),
    );
    
    if (result == true && mounted) {
      await _refreshData();
    }
  }

  void _navigateToWasteDeposit(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur Setor Sampah akan segera tersedia!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _navigateToDropboxMap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur Peta Dropbox akan segera tersedia!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _navigateToHistory(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur Riwayat akan segera tersedia!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _navigateToChallenge(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur EcoChallenge akan segera tersedia!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitur Notifikasi akan segera tersedia!'),
        backgroundColor: Color(0xFF4CAF50),
      ),
    );
  }

  void _showFeatureUnavailable(String? reason) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(reason ?? 'Fitur sedang tidak tersedia'),
        backgroundColor: Colors.orange[700],
      ),
    );
  }
}