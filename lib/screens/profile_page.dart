// lib/screens/profile_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';
import 'package:ecocycle_app/screens/personal_info_screen.dart';
import 'package:ecocycle_app/screens/invite_friend_screen.dart';
import 'package:ecocycle_app/screens/biography_screen.dart';
import 'package:ecocycle_app/screens/edit_profile_screen.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // FIXED: Access Map data correctly
    final userName = authProvider.user?['name'] ?? 'Username';

    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      body: Stack(
        children: [
          _buildHeader(),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildProfileAvatar(userName),
                const SizedBox(height: 30),
                _buildProfileMenu(context, Icons.person_outline, 'Personal Information', () {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PersonalInfoScreen()));
                }),
                _buildProfileMenu(context, Icons.group_add_outlined, 'Invite a Friend', () {
                  Navigator.push(context, MaterialPageRoute(builder: (ctx) => const InviteFriendScreen()));
                }),
                _buildProfileMenu(context, Icons.description_outlined, 'Biography', () {
                   Navigator.push(context, MaterialPageRoute(builder: (ctx) => const BiographyScreen()));
                }),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (ctx) => const EditProfileScreen()));
                  },
                  child: const Text('Edit Profil', style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline)),
                ),
                const SizedBox(height: 50),
                _buildLogoutButton(context, authProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk header hijau melengkung
  Widget _buildHeader() {
    return Container(
      height: 200,
      decoration: const BoxDecoration(
        color: Color(0xFF004d00),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
    );
  }

  // Widget untuk foto profil dan nama
  Widget _buildProfileAvatar(String name) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 55,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF00695C),
            child: Icon(Icons.person, color: Colors.white, size: 60),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Widget untuk membuat satu baris menu
  Widget _buildProfileMenu(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[800]),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk tombol logout
  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return ElevatedButton(
      onPressed: () {
        authProvider.logout();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange[800],
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: const Text(
        'Logout',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}