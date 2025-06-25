// lib/screens/auth_wrapper.dart - FIXED ALL SYNTAX ERRORS
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
  bool _shouldShowMapsFirst = true;

  @override
  void initState() {
    super.initState();
    debugPrint('🏠 AuthWrapper initialized');
    
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

    await _checkUserPreference();
  }

  Future<void> _checkUserPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSetPreference = prefs.getBool('has_set_home_preference') ?? false;
      
      if (!hasSetPreference) {
        _shouldShowMapsFirst = true;
      } else {
        _shouldShowMapsFirst = prefs.getBool('show_maps_first') ?? false;
      }
      
      setState(() {});
    } catch (e) {
      debugPrint('❌ Error checking user preference: $e');
      _shouldShowMapsFirst = true;
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

        if (auth.isLoading || !auth.isInitialized) {
          debugPrint('🏠 Showing loading screen');
          return Scaffold(
            backgroundColor: const Color(0xFF121212),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.eco,
                    size: 80,
                    color: Color(0xFF4CAF50),
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
                  const Text(
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

        if (auth.isLoggedIn && auth.isAuthenticated) {
          debugPrint('✅ User is authenticated');
          
          if (_shouldShowMapsFirst) {
            debugPrint('🗺️ Showing MapPage first');
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
          const MapPage(),
          
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
          
          Positioned(
            top: 60,
            right: 20,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: "settings",
                onPressed: () => _showPreferenceDialog(context),
                backgroundColor: Colors.white.withOpacity(0.9),
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
                _setPreference(context, true);
              },
              child: const Text('Maps Dulu'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _setPreference(context, false);
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

class SimpleAuthWrapper extends StatelessWidget {
  const SimpleAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        debugPrint('🏠 SimpleAuthWrapper - isLoggedIn: ${auth.isLoggedIn}');
        
        if (auth.isLoggedIn) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}