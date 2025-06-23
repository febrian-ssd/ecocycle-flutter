// lib/screens/auth_wrapper.dart - ENHANCED DEBUG VERSION
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
        debugPrint('   token: ${auth.token?.substring(0, 10) ?? 'null'}...');
        debugPrint('   user: ${auth.user?.keys ?? 'null'}');

        // Show loading screen if loading
        if (auth.isLoading) {
          debugPrint('🏠 Showing loading screen');
          return const Scaffold(
            backgroundColor: Color(0xFF424242),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }

        // If already logged in, show home screen
        if (auth.isLoggedIn) {
          debugPrint('✅ User is logged in, showing HomeScreen');
          return const HomeScreen();
        } else {
          debugPrint('❌ User not logged in, checking auto-login...');
          
          // Try auto-login
          return FutureBuilder<bool>(
            future: auth.tryAutoLogin(),
            builder: (ctx, authResultSnapshot) {
              debugPrint('🔄 FutureBuilder state: ${authResultSnapshot.connectionState}');
              debugPrint('🔄 FutureBuilder hasData: ${authResultSnapshot.hasData}');
              debugPrint('🔄 FutureBuilder data: ${authResultSnapshot.data}');
              debugPrint('🔄 FutureBuilder hasError: ${authResultSnapshot.hasError}');
              
              if (authResultSnapshot.hasError) {
                debugPrint('❌ Auto-login error: ${authResultSnapshot.error}');
              }
              
              if (authResultSnapshot.connectionState == ConnectionState.waiting) {
                debugPrint('⏳ Auto-login in progress, showing loading');
                return const Scaffold(
                  backgroundColor: Color(0xFF424242),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 16),
                        Text(
                          'Checking authentication...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Check auth state again after auto-login attempt
              debugPrint('🔍 After auto-login - isLoggedIn: ${auth.isLoggedIn}');
              
              if (auth.isLoggedIn) {
                debugPrint('✅ Auto-login successful, showing HomeScreen');
                return const HomeScreen();
              } else {
                debugPrint('❌ Auto-login failed or no saved credentials, showing LoginScreen');
                return const LoginScreen();
              }
            },
          );
        }
      },
    );
  }
}

// Alternative simplified AuthWrapper for testing
class SimpleAuthWrapper extends StatelessWidget {
  const SimpleAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        debugPrint('🏠 SimpleAuthWrapper - isLoggedIn: ${auth.isLoggedIn}');
        
        // Simple direct check
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
        backgroundColor: Colors.orange,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('isLoggedIn: ${auth.isLoggedIn}'),
                Text('isAuthenticated: ${auth.isAuthenticated}'),
                Text('isLoading: ${auth.isLoading}'),
                Text('token: ${auth.token ?? 'null'}'),
                Text('user: ${auth.user ?? 'null'}'),
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: () {
                    auth.debugCurrentState();
                  },
                  child: const Text('Print Debug Info'),
                ),
                
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                    );
                  },
                  child: const Text('Force Navigate to Home'),
                ),
                
                ElevatedButton(
                  onPressed: () {
                    auth.logout();
                  },
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}