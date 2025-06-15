// lib/screens/biography_screen.dart
import 'package:flutter/material.dart';

class BiographyScreen extends StatelessWidget {
  const BiographyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      appBar: AppBar(
        title: const Text('Biography', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF004d00),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'EcoCycle adalah platform revolusioner yang bertujuan untuk mengubah cara kita memandang sampah. Dengan mengintegrasikan teknologi dan kesadaran lingkungan, kami memberikan insentif bagi setiap individu untuk memilah dan mendaur ulang sampah mereka.\n\nSetiap kali Anda membuang sampah pada dropbox kami yang terhubung, Anda tidak hanya membantu membersihkan lingkungan, tetapi juga mendapatkan imbalan berupa EcoCoins yang dapat ditukarkan dengan uang tunai atau digunakan untuk berbagai transaksi. Bergabunglah dengan gerakan kami untuk menciptakan siklus ekonomi yang berkelanjutan dan planet yang lebih hijau untuk generasi mendatang.',
          style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}