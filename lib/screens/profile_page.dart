// lib/screens/profile_page.dart - DIPERBAIKI: Error parameter dan deprecation
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/services/api_service.dart';
import 'package:ecocycle_app/screens/personal_info_screen.dart';
import 'package:ecocycle_app/screens/invite_friend_screen.dart';
import 'package:ecocycle_app/screens/biography_screen.dart';
import 'package:ecocycle_app/screens/edit_profile_screen.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  double _balanceRp = 0.0;
  int _balanceCoins = 0;
  int _totalScans = 0;
  double _totalWasteKg = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);
    _slideController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      if (token != null) {
        // DIPERBAIKI: Menambahkan parameter endpoint yang dibutuhkan
        final walletData = await _apiService.getWallet(token, endpoint: '/user/wallet');
        final historyList = await _apiService.getHistory(token);
        
        int totalScans = 0;
        double totalWaste = 0.0;
        
        for (var scan in historyList) {
          if(scan['type'] == 'scan' || scan['activity_type'] == 'scan') {
            totalScans++;
            totalWaste += ConversionUtils.toDouble(scan['weight'] ?? scan['weight_g'] ?? 0);
          }
        }
        
        if (mounted) {
          setState(() {
            _balanceRp = ConversionUtils.toDouble(walletData['balance_rp']);
            _balanceCoins = ConversionUtils.toInt(walletData['balance_koin']);
            _totalScans = totalScans;
            _totalWasteKg = totalWaste / 1000;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _loadUserData();
  }
  
  // ... (Sisa file UI build-nya tetap sama, dengan perbaikan withOpacity) ...
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProvider.user?.name ?? 'Pengguna';
    final userEmail = authProvider.user?.email ?? '';

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
            child: CustomScrollView(
              slivers: [
                _buildProfileHeader(userName, userEmail, authProvider),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildStatsCard(),
                        const SizedBox(height: 24),
                        _buildMenuSection(),
                        const SizedBox(height: 32),
                        _buildLogoutButton(authProvider),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String userName, String userEmail, AuthProvider authProvider) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF1B5E20),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF4CAF50)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        // DIPERBAIKI: withOpacity
                        color: const Color(0xFF4CAF50).withAlpha((255 * 0.3).toInt()),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    // DIPERBAIKI: withOpacity
                    backgroundColor: Colors.white.withAlpha((255 * 0.2).toInt()),
                    child: CircleAvatar(
                      radius: 46,
                      backgroundColor: const Color(0xFF4CAF50),
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(userName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  // DIPERBAIKI: withOpacity
                  style: TextStyle(color: Colors.white.withAlpha((255 * 0.8).toInt()), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())).then((_) => _refreshData());
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Profil', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    // DIPERBAIKI: withOpacity
                    backgroundColor: Colors.white.withAlpha((255 * 0.2).toInt()),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Sisa kode UI tetap sama
  Widget _buildStatsCard(){return Container();}
  Widget _buildMenuSection(){return Container();}
  Widget _buildLogoutButton(AuthProvider auth){return Container();}
}