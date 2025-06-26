// lib/screens/auth_wrapper.dart - MAP AS DEFAULT HOME
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/screens/home_screen.dart';
import 'package:ecocycle_app/screens/login_screen.dart';
import 'package:ecocycle_app/screens/map_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showMapAsHome = true; // Default: Map sebagai beranda
  bool _hasCheckedPreference = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 AuthWrapper initialized');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuthAndPreferences();
    });
  }

  Future<void> _initializeAuthAndPreferences() async {
    debugPrint('🏠 AuthWrapper initializing auth and preferences...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Initialize auth first
    if (!authProvider.isInitialized) {
      await authProvider.initializeAuth();
    }

    // Then check user preference
    await _checkUserPreference();
  }

  Future<void> _checkUserPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user has set a preference
      final hasSetPreference = prefs.getBool('has_set_home_preference') ?? false;
      
      if (hasSetPreference) {
        // Use saved preference
        _showMapAsHome = prefs.getBool('show_map_as_home') ?? true;
      } else {
        // Default: Map as home (sesuai permintaan)
        _showMapAsHome = true;
      }
      
      setState(() {
        _hasCheckedPreference = true;
      });
      
      debugPrint('🏠 User preference checked: Map as home = $_showMapAsHome');
    } catch (e) {
      debugPrint('❌ Error checking user preference: $e');
      setState(() {
        _showMapAsHome = true; // Default fallback
        _hasCheckedPreference = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 AuthWrapper building...');
    
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        debugPrint('🏠 AuthWrapper Consumer builder called');
        debugPrint('🔍 AuthProvider state:');
        debugPrint('   isLoggedIn: ${auth.isLoggedIn}');
        debugPrint('   isAuthenticated: ${auth.isAuthenticated}');
        debugPrint('   isLoading: ${auth.isLoading}');
        debugPrint('   isInitialized: ${auth.isInitialized}');
        debugPrint('   isConnected: ${auth.isConnected}');

        // Show loading while initializing
        if (auth.isLoading || !auth.isInitialized || !_hasCheckedPreference) {
          debugPrint('🏠 Showing loading screen');
          return Scaffold(
            backgroundColor: const Color(0xFF121212),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF4CAF50).withOpacity(0.3),
                          const Color(0xFF4CAF50),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'EcoCycle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    auth.isConnected 
                        ? 'Menghubungkan ke server...'
                        : 'Memeriksa koneksi...',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show login if not authenticated
        if (!auth.isLoggedIn || !auth.isAuthenticated) {
          debugPrint('❌ User not authenticated, showing LoginScreen');
          return const LoginScreen();
        }

        // Show Map or HomeScreen based on preference
        debugPrint('✅ User authenticated');
        
        if (_showMapAsHome) {
          debugPrint('🗺️ Showing MapPage as home');
          return MapScreenWrapper(
            onNavigateToApp: () {
              setState(() {
                _showMapAsHome = false;
              });
              _saveUserPreference(false);
            },
          );
        } else {
          debugPrint('🏠 Showing HomeScreen');
          return const HomeScreen();
        }
      },
    );
  }

  Future<void> _saveUserPreference(bool showMapAsHome) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_map_as_home', showMapAsHome);
      await prefs.setBool('has_set_home_preference', true);
      debugPrint('✅ User preference saved: Map as home = $showMapAsHome');
    } catch (e) {
      debugPrint('❌ Error saving user preference: $e');
    }
  }
}

class MapScreenWrapper extends StatelessWidget {
  final VoidCallback onNavigateToApp;

  const MapScreenWrapper({
    super.key,
    required this.onNavigateToApp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map as fullscreen background
          const MapPage(),
          
          // Top overlay with app title and menu
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // App Logo and Title
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.eco,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'EcoCycle',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Settings button
                      IconButton(
                        onPressed: () => _showHomePreferenceDialog(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Bottom navigation overlay
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(
                    icon: Icons.home,
                    label: 'Home App',
                    onTap: onNavigateToApp,
                    isPrimary: true,
                  ),
                  _buildNavButton(
                    icon: Icons.account_balance_wallet,
                    label: 'EcoPay',
                    onTap: () => _navigateToEcoPay(context),
                  ),
                  _buildNavButton(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan',
                    onTap: () => _navigateToScan(context),
                  ),
                  _buildNavButton(
                    icon: Icons.person,
                    label: 'Profile',
                    onTap: () => _navigateToProfile(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isPrimary 
              ? const Color(0xFF4CAF50) 
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHomePreferenceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Pengaturan Beranda',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Pilih tampilan yang ingin ditampilkan setelah login:',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Keep map as home (do nothing)
              },
              child: const Text('Tetap Map'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _setPreference(context, false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('Ganti ke App'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setPreference(BuildContext context, bool showMapAsHome) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_map_as_home', showMapAsHome);
      await prefs.setBool('has_set_home_preference', true);
      
      if (!showMapAsHome) {
        onNavigateToApp();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            showMapAsHome 
                ? 'Map akan ditampilkan sebagai beranda'
                : 'App akan ditampilkan sebagai beranda',
          ),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error setting preference: $e');
    }
  }

  void _navigateToEcoPay(BuildContext context) {
    // Navigate to EcoPay while keeping map in background
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) => const Scaffold(
                  body: Center(
                    child: Text(
                      'EcoPay will be imported here',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: Center(
            child: Text(
              'Scan Screen will be imported here',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF121212),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: const Center(
          child: Text(
            'Profile Screen will be imported here',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// Simple fallback for emergency use
class SimpleAuthWrapper extends StatelessWidget {
  const SimpleAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        debugPrint('🏠 SimpleAuthWrapper - isLoggedIn: ${auth.isLoggedIn}');
        
        if (auth.isLoggedIn) {
          return const MapPage(); // Always show map in simple mode
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}