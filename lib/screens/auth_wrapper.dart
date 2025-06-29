// lib/screens/auth_wrapper.dart
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isInitialized) {
        authProvider.initializeAuth();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading || !auth.isInitialized) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  SizedBox(height: 20),
                  Text('Memuat...', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          );
        }

        if (auth.isLoggedIn) {
          debugPrint('✅ User authenticated, showing HomeScreen');
          return const HomeScreen();
        } else {
          debugPrint('❌ User not authenticated, showing LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}