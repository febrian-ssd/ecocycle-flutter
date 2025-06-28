// lib/models/transaction.dart - DIPERBAIKI: Support semua transaction types
import 'package:ecocycle_app/utils/conversion_utils.dart';

class Transaction {
  final int id;
  final String type;
  final double amountRp;
  final int amountCoins;
  final String description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    required this.amountRp,
    required this.amountCoins,
    required this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: ConversionUtils.toInt(json['id']),
      type: json['type'] as String? ?? '',
      amountRp: ConversionUtils.toDouble(json['amount_rp']),
      amountCoins: ConversionUtils.toInt(json['amount_coins']),
      description: json['description'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount_rp': amountRp,
      'amount_coins': amountCoins,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  String get formattedAmountRp => ConversionUtils.formatCurrency(amountRp.abs());
  
  String get formattedAmountCoins => '${ConversionUtils.formatNumber(amountCoins.abs())} coins';
  
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Baru saja';
        }
        return '${difference.inMinutes} menit yang lalu';
      }
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  // PERBAIKAN: Support semua transaction types
  String get typeDisplayName {
    const Map<String, String> typeMapping = {
      'topup': 'Top Up',
      'manual_topup': 'Top Up Manual',
      'coin_exchange_to_rp': 'Tukar Koin',
      'scan_reward': 'Reward Scan',
      'transfer_out': 'Transfer Keluar',
      'transfer_in': 'Transfer Masuk',
      'exchange_coins': 'Tukar Koin',
    };
    
    return typeMapping[type.toLowerCase()] ?? type;
  }

  // PERBAIKAN: Logic income/expense yang lebih akurat
  bool get isIncome {
    // Income transaction types
    const incomeTypes = [
      'topup',
      'manual_topup', 
      'scan_reward',
      'transfer_in',
      'coin_exchange_to_rp',
    ];
    
    // Check by type first
    if (incomeTypes.contains(type.toLowerCase())) return true;
    
    // Fallback: check by amount
    if (amountRp > 0 || amountCoins > 0) return true;
    
    return false;
  }

  bool get isExpense {
    const expenseTypes = ['transfer_out', 'exchange_coins'];
    
    if (expenseTypes.contains(type.toLowerCase())) return true;
    if (amountRp < 0 || amountCoins < 0) return true;
    
    return false;
  }

  @override
  String toString() {
    return 'Transaction{id: $id, type: $type, amountRp: $amountRp, amountCoins: $amountCoins, description: $description, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Transaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}