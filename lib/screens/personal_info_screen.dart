// lib/screens/personal_info_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil data user dari provider untuk ditampilkan
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: AppBar(
        title: const Text('Personal Information', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF004d00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: Colors.grey[800],
          child: Column(
            mainAxisSize: MainAxisSize.min, // Agar card tidak memenuhi layar
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: Colors.white70),
                title: const Text('Nama', style: TextStyle(color: Colors.white70)),
                subtitle: Text(user?.name ?? 'Tidak ada data', style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.white70),
                title: const Text('Email', style: TextStyle(color: Colors.white70)),
                subtitle: Text(user?.email ?? 'Tidak ada data', style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}