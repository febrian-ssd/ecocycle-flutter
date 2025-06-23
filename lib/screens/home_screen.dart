// lib/screens/home_screen.dart - FINAL FIX

import 'package:flutter/material.dart';

// Import semua halaman dengan path yang benar
import 'package:ecocycle_app/screens/map_page.dart';
import 'package:ecocycle_app/screens/ecopay_page.dart';
import 'package:ecocycle_app/screens/history_page.dart';
import 'package:ecocycle_app/screens/profile_page.dart'; 
import 'package:ecocycle_app/screens/scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Daftar halaman sekarang sudah lengkap menunjuk ke file masing-masing
  static final List<Widget> _pages = <Widget>[
    const MapPage(),
    const EcoPayPage(), // FIXED: Added const
    const SizedBox.shrink(),
    const HistoryPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      _scanButtonPressed();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  void _scanButtonPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'EcoPay'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF004d00),
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white70,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scanButtonPressed,
        backgroundColor: Colors.orange,
        shape: const CircleBorder(),
        elevation: 2.0,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}