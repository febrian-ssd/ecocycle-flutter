v=// lib/screens/auth_wrapper.dart - PERBAIKAN UNTUK LANGSUNG KE MAPS
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
  bool _shouldShowMapsFirst = true; // Flag untuk menentukan apakah harus ke maps dulu

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 AuthWrapper initialized');
    
    // Initialize auth state when AuthWrapper is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    debugPrint('🏠 AuthWrapper initializing auth...');
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isInitialized) {
      await authProvider.initializeAuth();
    }

    // Check user preference untuk home screen vs maps
    await _checkUserPreference();
  }

  Future<void> _checkUserPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Cek apakah user pernah mengatur preferensi
      final hasSetPreference = prefs.getBool('has_set_home_preference') ?? false;
      
      if (!hasSetPreference) {
        // Jika belum pernah set, default ke maps (sesuai behavior lama)
        _shouldShowMapsFirst = true;
      } else {
        // Jika sudah pernah set, ikuti preferensi user
        _shouldShowMapsFirst = prefs.getBool('show_maps_first') ?? false;
      }
      
      setState(() {});
    } catch (e) {
      debugPrint('❌ Error checking user preference: $e');
      _shouldShowMapsFirst = true; // Default ke maps jika error
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 AuthWrapper building...');
    
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        debugPrint('🏠 AuthWrapper Consumer builder called');
        debugPrint('🔍 AuthProvider state in AuthWrapper:');
        debugPrint('   isLoggedIn: ${auth.isLoggedIn}');
        debugPrint('   isAuthenticated: ${auth.isAuthenticated}');
        debugPrint('   isLoading: ${auth.isLoading}');
        debugPrint('   isInitialized: ${auth.isInitialized}');

        // Show loading screen while initializing or processing
        if (auth.isLoading || !auth.isInitialized) {
          debugPrint('🏠 Showing loading screen (loading: ${auth.isLoading}, initialized: ${auth.isInitialized})');
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Icon(
                    Icons.eco,
                    size: 80,
                    color: Color(0xFF4CAF50),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'EcoCycle',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 40),
                  CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
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

        // If authenticated, decide which screen to show
        if (auth.isLoggedIn && auth.isAuthenticated) {
          debugPrint('✅ User is authenticated');
          
          // PERBAIKAN: Pilih screen berdasarkan preferensi
          if (_shouldShowMapsFirst) {
            debugPrint('🗺️ Showing MapPage first (as requested)');
            return MapScreenWrapper(
              onNavigateToHome: () {
                setState(() {
                  _shouldShowMapsFirst = false;
                });
                _saveUserPreference(false);
              },
            );
          } else {
            debugPrint('🏠 Showing HomeScreen');
            return const HomeScreen();
          }
        } else {
          debugPrint('❌ User not authenticated, showing LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }

  Future<void> _saveUserPreference(bool showMapsFirst) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_maps_first', showMapsFirst);
      await prefs.setBool('has_set_home_preference', true);
    } catch (e) {
      debugPrint('❌ Error saving user preference: $e');
    }
  }
}

// Wrapper untuk MapPage dengan tombol navigasi ke Home
class MapScreenWrapper extends StatelessWidget {
  final VoidCallback onNavigateToHome;

  const MapScreenWrapper({
    super.key,
    required this.onNavigateToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map content
          const MapPage(),
          
          // Floating action button untuk ke Home
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: "home_nav",
                  onPressed: onNavigateToHome,
                  backgroundColor: const Color(0xFF4CAF50),
                  child: const Icon(
                    Icons.home,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Home',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Settings button untuk mengubah preferensi
          Positioned(
            top: 60,
            right: 20,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: "settings",
                onPressed: () => _showPreferenceDialog(context),
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPreferenceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2A2A),
          title: const Text(
            'Pengaturan Tampilan',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Pilih halaman yang ingin ditampilkan setelah login:',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _setPreference(context, true); // Maps first
              },
              child: const Text('Maps Dulu'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _setPreference(context, false); // Home first
              },
              child: const Text('Home Dulu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setPreference(BuildContext context, bool showMapsFirst) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_maps_first', showMapsFirst);
      await prefs.setBool('has_set_home_preference', true);
      
      if (!showMapsFirst) {
        onNavigateToHome();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            showMapsFirst 
                ? 'Akan menampilkan Maps setelah login'
                : 'Akan menampilkan Home setelah login',
          ),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error setting preference: $e');
    }
  }
}

// Alternative simple AuthWrapper for testing without auto-login
class SimpleAuthWrapper extends StatelessWidget {
  const SimpleAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        debugPrint('🏠 SimpleAuthWrapper - isLoggedIn: ${auth.isLoggedIn}');
        
        // Simple direct check without auto-initialization
        if (auth.isLoggedIn) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}