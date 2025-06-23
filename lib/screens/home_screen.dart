// lib/screens/home_screen.dart - FIXED IMPORTS
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
    const EcoPayPage(),
    const SizedBox.shrink(), // Placeholder untuk scan button
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
    debugPrint('🔄 Navigating to ScanScreen');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScanScreen(),
      ),
    ).then((_) {
      debugPrint('✅ Returned from ScanScreen');
    }).catchError((error) {
      debugPrint('❌ Error navigating to ScanScreen: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka scanner: $error'),
          backgroundColor: Colors.red[700],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF004d00),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'EcoPay',
            ),
            BottomNavigationBarItem(
              icon: SizedBox.shrink(),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.white70,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _scanButtonPressed,
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          child: const Icon(
            Icons.qr_code_scanner,
            size: 32,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}