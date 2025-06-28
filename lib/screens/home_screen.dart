// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:ecocycle_app/screens/map_page.dart';
import 'package:ecocycle_app/screens/ecopay_page.dart';
import 'package:ecocycle_app/screens/scan_screen.dart';
import 'package:ecocycle_app/screens/history_page.dart';
import 'package:ecocycle_app/screens/profile_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _pages = [
    const MapPage(),
    const EcoPayPage(),
    const SizedBox.shrink(), // Placeholder for the middle button
    const HistoryPage(),
    const ProfilePage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ScanScreen()),
      );
      return;
    }
    
    // Adjust index for PageView since ScanScreen is not in it
    int pageIndex = index > 2 ? index - 1 : index;

    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          // Adjust index from PageView to match BottomNavBar
          int selectedIndex = index >= 2 ? index + 1 : index;
          setState(() {
            _selectedIndex = selectedIndex;
          });
        },
        children: [
          _pages[0],
          _pages[1],
          _pages[3],
          _pages[4],
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _onItemTapped(2),
      backgroundColor: Colors.orange,
      shape: const CircleBorder(),
      elevation: 4.0,
      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      color: const Color(0xFF1E1E1E),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildNavItem(icon: Icons.home, label: 'Home', index: 0),
          _buildNavItem(icon: Icons.account_balance_wallet, label: 'EcoPay', index: 1),
          const SizedBox(width: 40), // Ruang untuk Floating Action Button
          _buildNavItem(icon: Icons.history, label: 'History', index: 3),
          _buildNavItem(icon: Icons.person, label: 'Profile', index: 4),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final bool isSelected = _selectedIndex == index;
    return IconButton(
      icon: Icon(
        icon,
        color: isSelected ? const Color(0xFF4CAF50) : Colors.grey[600],
        size: 28,
      ),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }
}