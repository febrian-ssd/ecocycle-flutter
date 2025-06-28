// lib/widgets/wallet_error_widget.dart - Tanpa Perubahan, sekarang akan berfungsi
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';

class WalletErrorWidget extends StatelessWidget {
  final bool showRetryButton;
  final VoidCallback? onRetry;
  
  const WalletErrorWidget({
    super.key,
    this.showRetryButton = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.hasWalletError) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[300]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Layanan Wallet Tidak Tersedia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange[800])),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                authProvider.getWalletStatusMessage(),
                style: TextStyle(fontSize: 14, color: Colors.orange[700]),
              ),
              if (showRetryButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onRetry ?? () => authProvider.refreshWalletData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange[700], side: BorderSide(color: Colors.orange[300]!)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ... (Widget WalletErrorBanner dan WalletBalanceCard juga akan berfungsi tanpa perubahan) ...