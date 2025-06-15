// lib/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/screens/home_screen.dart';
import 'package:ecocycle_app/screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoggedIn) {
          return const HomeScreen();
        } else {
          return FutureBuilder(
            future: auth.tryAutoLogin(),
            builder: (ctx, authResultSnapshot) {
              if (authResultSnapshot.connectionState == ConnectionState.waiting) {
                // Tampilkan loading screen sederhana saat memeriksa token
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
            },
          );
        }
      },
    );
  }
}