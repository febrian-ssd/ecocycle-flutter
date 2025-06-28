// lib/screens/transaksi_berhasil_screen.dart - Enhanced Success Screen
import 'package:flutter/material.dart';
import 'package:ecocycle_app/utils/conversion_utils.dart'; // Import untuk formatCurrency

class TransaksiBerhasilScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final int? coins;
  final double? amount;
  final IconData? icon;
  final Color? color;

  const TransaksiBerhasilScreen({
    super.key,
    this.title = 'Transaksi Berhasil',
    this.subtitle = 'Transaksi Anda telah berhasil diproses',
    this.coins,
    this.amount,
    this.icon,
    this.color,
  });

  @override
  State<TransaksiBerhasilScreen> createState() => _TransaksiBerhasilScreenState();
}

class _TransaksiBerhasilScreenState extends State<TransaksiBerhasilScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _bounceController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _bounceAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
    
    // Start animations with delays
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scaleController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _bounceController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Success Icon with Animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (widget.color ?? const Color(0xFF4CAF50)).withValues(alpha: 0.2),
                      boxShadow: [
                        BoxShadow(
                          color: (widget.color ?? const Color(0xFF4CAF50)).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon ?? Icons.check_circle,
                      color: widget.color ?? const Color(0xFF4CAF50),
                      size: 60,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                ScaleTransition(
                  scale: _bounceAnimation,
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Subtitle
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Coins/Amount Display (if provided)
                if (widget.coins != null || widget.amount != null)
                  ScaleTransition(
                    scale: _bounceAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (widget.color ?? const Color(0xFF4CAF50)).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (widget.coins != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.eco,
                                  color: widget.color ?? const Color(0xFF4CAF50),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${widget.coins} EcoCoins',
                                  style: TextStyle(
                                    color: widget.color ?? const Color(0xFF4CAF50),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'telah ditambahkan ke akun Anda',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (widget.amount != null) ...[
                            // DIPERBAIKI: Hapus icon dolar dan gunakan formatCurrency dari ConversionUtils
                            Text(
                              ConversionUtils.formatCurrency(widget.amount!),
                              style: TextStyle(
                                color: widget.color ?? const Color(0xFF4CAF50),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                
                const Spacer(),
                
                // Action Buttons
                Column(
                  children: [
                    // Primary Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color ?? const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Kembali ke Beranda',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Secondary Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Kembali',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Success Screen Variants for different transaction types
class ScanBerhasilScreen extends TransaksiBerhasilScreen {
  const ScanBerhasilScreen({
    super.key,
    required int coins,
    String? location,
  }) : super(
          title: 'Scan Berhasil!',
          subtitle: location != null 
              ? 'Scan di $location berhasil diproses'
              : 'Scan Anda berhasil diproses',
          coins: coins,
          icon: Icons.qr_code_scanner,
          color: const Color(0xFF4CAF50),
        );
}

class TransferBerhasilScreen extends TransaksiBerhasilScreen {
  const TransferBerhasilScreen({
    super.key,
    required double amount,
    String? recipientEmail,
  }) : super(
          title: 'Transfer Berhasil!',
          subtitle: recipientEmail != null 
              ? 'Transfer ke $recipientEmail berhasil'
              : 'Transfer Anda berhasil diproses',
          amount: amount,
          icon: Icons.send,
          color: const Color(0xFF2196F3),
        );
}

class TopupBerhasilScreen extends TransaksiBerhasilScreen {
  const TopupBerhasilScreen({
    super.key,
    required double amount,
  }) : super(
          title: 'Top Up Berhasil!',
          subtitle: 'Saldo Anda telah berhasil ditambahkan',
          amount: amount,
          icon: Icons.add_circle,
          color: const Color(0xFF4CAF50),
        );
}

class ExchangeBerhasilScreen extends TransaksiBerhasilScreen {
  const ExchangeBerhasilScreen({
    super.key,
    required int coins,
    required double amount,
  }) : super(
          title: 'Tukar Koin Berhasil!',
          subtitle: '$coins EcoCoins berhasil ditukar menjadi saldo',
          amount: amount,
          icon: Icons.swap_horiz,
          color: const Color(0xFFFF9800),
        );
}