// lib/screens/history_page.dart

import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  // DATA PALSU / DUMMY untuk tampilan
  final List<Map<String, String>> dummyHistory = const [
    {
      'location': 'DropBox Medan Area',
      'street': 'Jl. Sampingan',
      'wasteType': 'Plastik',
      'weight': '15 g',
      'coins': '15 koin',
    },
    {
      'location': 'DropBox Medan Barat',
      'street': 'Jl. Kenangan',
      'wasteType': 'Kertas',
      'weight': '25 g',
      'coins': '25 koin',
    },
    {
      'location': 'DropBox Helvetia',
      'street': 'Jl. Veteran',
      'wasteType': 'Botol Kaca',
      'weight': '150 g',
      'coins': '150 koin',
    },
    {
      'location': 'DropBox Medan Timur',
      'street': 'Jl. Pahlawan',
      'wasteType': 'Kaleng',
      'weight': '50 g',
      'coins': '50 koin',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF303030),
      // Kita gunakan CustomScrollView untuk membuat header yang bisa "mengambang"
      body: CustomScrollView(
        slivers: [
          // Header besar dengan tulisan "History"
          SliverAppBar(
            backgroundColor: const Color(0xFF004d00),
            expandedHeight: 150.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: const Text(
                'History',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28.0,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF004d00),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
            ),
          ),

          // Daftar riwayat scan
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final historyItem = dummyHistory[index];
                return _buildHistoryCard(historyItem);
              },
              childCount: dummyHistory.length,
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk membuat satu kartu riwayat
  Widget _buildHistoryCard(Map<String, String> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        color: Colors.grey[300],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bagian Kiri (Lokasi)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['location']!,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['street']!,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              // Bagian Kanan (Detail Sampah)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item['wasteType']!,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['weight']!,
                    style: const TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['coins']!,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}