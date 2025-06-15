// lib/screens/ecopay_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ecocycle_app/screens/isi_saldo_screen.dart';
import 'package:ecocycle_app/screens/transfer_screen.dart';
import 'package:ecocycle_app/screens/tukar_koin_screen.dart';

// Hapus 'const' dari constructor karena '_rpFormatter' tidak const
class EcoPayPage extends StatelessWidget {
  EcoPayPage({super.key}); // <-- PERUBAHAN DI SINI

  // Helper untuk format Rupiah
  final _rpFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp. ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      // AppBar Kustom sesuai desain
      appBar: AppBar(
        title: const Text('EcoPay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
        backgroundColor: const Color(0xFF004d00),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalletCard(),
            const SizedBox(height: 24),
            _buildActionButtons(context),
            const SizedBox(height: 24),
            _buildTransactionHistory(),
          ],
        ),
      ),
    );
  }

  // --- Widget-widget untuk setiap bagian halaman ---

  Widget _buildWalletCard() {
    // DATA PALSU UNTUK TAMPILAN
    const double balanceRp = 150000;
    const int balanceCoins = 150;

    return Card(
      color: const Color(0xFF00695C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Text('$balanceCoins COINS', style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Saldo Anda', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF004D40),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(_rpFormatter.format(balanceRp), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _actionButton('Isi Saldo', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const IsiSaldoScreen()));
        }),
        _actionButton('Transfer', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TransferScreen()));
        }),
        _actionButton('Tukar Koin', () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const TukarKoinScreen()));
        }),
      ],
    );
  }

  Widget _actionButton(String title, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[700],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildTransactionHistory() {
    // DATA PALSU UNTUK RIWAYAT TRANSAKSI
    final List<Map<String, dynamic>> transactions = [
      {'title': 'Top Up', 'date': '1 May 2025', 'amount': 'Rp.2000', 'isIncome': true},
      {'title': 'Tukar koin', 'date': '1 May 2025', 'amount': '- 200 koin', 'isIncome': false},
    ];

    return Card(
      color: const Color(0xFF004d00),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: const Text('Riwayat Transaksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.keyboard_arrow_up, color: Colors.greenAccent),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: [
          Container(
            color: Colors.grey[800],
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (context, index) => Divider(color: Colors.grey[700], height: 1),
              itemBuilder: (context, index) {
                final trx = transactions[index];
                return ListTile(
                  title: Text(trx['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(trx['date'], style: const TextStyle(color: Colors.white70)),
                  trailing: Text(
                    trx['amount'],
                    style: TextStyle(
                      color: trx['isIncome'] ? Colors.greenAccent[400] : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}