// lib/screens/transfer_success_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransferSuccessScreen extends StatelessWidget {
  final int amount;
  final String recipientEmail;
  final String note;

  const TransferSuccessScreen({
    super.key,
    required this.amount,
    required this.recipientEmail,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    ),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Transfer Berhasil',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the close button
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Success Animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4CAF50),
                  size: 60,
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                'Transfer Berhasil!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Uang telah berhasil dikirim',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Transfer Details
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Transfer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Amount
                    _buildDetailRow(
                      'Jumlah',
                      currencyFormatter.format(amount),
                      Icons.payments,
                      const Color(0xFF4CAF50),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Recipient
                    _buildDetailRow(
                      'Penerima',
                      recipientEmail,
                      Icons.person,
                      const Color(0xFF2196F3),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date & Time
                    _buildDetailRow(
                      'Waktu',
                      DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(DateTime.now()),
                      Icons.schedule,
                      const Color(0xFFFF9800),
                    ),
                    
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Catatan',
                        note,
                        Icons.note,
                        const Color(0xFF9C27B0),
                      ),
                    ],
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Action Buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Kembali ke Beranda',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        // Navigate to history or another transfer
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        // You can add navigation to history tab here
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      child: Text(
                        'Lihat Riwayat Transfer',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}