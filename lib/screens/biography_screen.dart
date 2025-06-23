import 'package:flutter/material.dart';

class BiographyScreen extends StatefulWidget {
  const BiographyScreen({super.key});

  @override
  State<BiographyScreen> createState() => _BiographyScreenState();
}

class _BiographyScreenState extends State<BiographyScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Tentang EcoCycle',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Hero Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.eco,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'EcoCycle',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Transforming Waste into Value',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Mission Section
                _buildSection(
                  icon: Icons.flag,
                  title: 'Misi Kami',
                  content: 'EcoCycle adalah platform revolusioner yang bertujuan untuk mengubah cara kita memandang sampah. Dengan mengintegrasikan teknologi dan kesadaran lingkungan, kami memberikan insentif bagi setiap individu untuk memilah dan mendaur ulang sampah mereka.',
                  color: const Color(0xFF4CAF50),
                ),
                
                const SizedBox(height: 20),
                
                // How it Works Section
                _buildSection(
                  icon: Icons.settings,
                  title: 'Cara Kerja',
                  content: 'Setiap kali Anda membuang sampah pada dropbox kami yang terhubung, Anda tidak hanya membantu membersihkan lingkungan, tetapi juga mendapatkan imbalan berupa EcoCoins yang dapat ditukarkan dengan uang tunai atau digunakan untuk berbagai transaksi.',
                  color: const Color(0xFF2196F3),
                ),
                
                const SizedBox(height: 20),
                
                // Impact Section
                _buildSection(
                  icon: Icons.public,
                  title: 'Dampak Lingkungan',
                  content: 'Bergabunglah dengan gerakan kami untuk menciptakan siklus ekonomi yang berkelanjutan dan planet yang lebih hijau untuk generasi mendatang. Setiap tindakan kecil Anda berkontribusi pada perubahan besar.',
                  color: const Color(0xFFFF9800),
                ),
                
                const SizedBox(height: 20),
                
                // Statistics Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3A3A3A)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Pencapaian Komunitas',
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
                            child: _buildStatItem('1,250+', 'Pengguna Aktif', Icons.people),
                          ),
                          Container(width: 1, height: 50, color: Colors.grey[700]),
                          Expanded(
                            child: _buildStatItem('5.2 Ton', 'Sampah Didaur Ulang', Icons.recycling),
                          ),
                          Container(width: 1, height: 50, color: Colors.grey[700]),
                          Expanded(
                            child: _buildStatItem('45', 'Dropbox Aktif', Icons.location_on),
                          ),
                        ],
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF4CAF50),
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}