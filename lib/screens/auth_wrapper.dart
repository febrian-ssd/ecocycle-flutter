// lib/screens/auth_wrapper.dart - DISEDERHANAKAN
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
    // Memastikan status autentikasi diperiksa saat widget pertama kali dibuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).initializeAuth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        // Tampilkan layar loading saat status autentikasi sedang diperiksa
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

        // Jika pengguna sudah login, tampilkan HomeScreen. Jika tidak, tampilkan LoginScreen.
        if (auth.isLoggedIn) {
          debugPrint('✅ Pengguna terautentikasi, menampilkan HomeScreen');
          return const HomeScreen();
        } else {
          debugPrint('❌ Pengguna tidak terautentikasi, menampilkan LoginScreen');
          return const LoginScreen();
        }
      },
    );
  }
}