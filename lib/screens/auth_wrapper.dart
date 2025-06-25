// lib/screens/auth_wrapper.dart - IMPROVED VERSION with better initialization
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/screens/home_screen.dart';
import 'package:ecocycle_app/screens/login_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
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
        debugPrint('   token: ${auth.token?.substring(0, 10) ?? 'null'}...');
        // FIXED: Accessing user as an object, not a map
        debugPrint('   user: ${auth.user?.toString() ?? 'null'}');

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

        // If authenticated, show home screen
        if (auth.isLoggedIn && auth.isAuthenticated) {
          debugPrint('✅ User is authenticated, showing HomeScreen');
          return const HomeScreen();
        } else {
          debugPrint('❌ User not authenticated, showing LoginScreen');
          return const LoginScreen();
        }
      },
    );
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

// Debug screen to manually test authentication state
class AuthDebugScreen extends StatelessWidget {
  const AuthDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Debug'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      backgroundColor: const Color(0xFF121212),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Authentication Debug Info',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildDebugRow('isLoggedIn', auth.isLoggedIn.toString()),
                _buildDebugRow('isAuthenticated', auth.isAuthenticated.toString()),
                _buildDebugRow('isLoading', auth.isLoading.toString()),
                _buildDebugRow('isInitialized', auth.isInitialized.toString()),
                _buildDebugRow('token', auth.token?.substring(0, 20) ?? 'null'),
                _buildDebugRow('user', auth.user?.toString() ?? 'null'),
                
                const SizedBox(height: 30),
                
                // Action buttons
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // FIXED: Method is available in the updated AuthProvider
                        auth.debugCurrentState();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                      ),
                      child: const Text('Print Debug Info'),
                    ),
                    
                    ElevatedButton(
                      onPressed: () async {
                        await auth.initializeAuth();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text('Re-initialize Auth'),
                    ),
                    
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const HomeScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('Force Navigate to Home'),
                    ),
                    
                    ElevatedButton(
                      onPressed: () {
                        auth.logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}