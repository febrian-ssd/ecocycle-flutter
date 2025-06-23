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
  String get formattedAmountRp => ConversionUtils.formatCurrency(amountRp);
  
  String get formattedAmountCoins => '${ConversionUtils.formatNumber(amountCoins)} coins';
  
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
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

  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'transfer_in':
        return 'Transfer Masuk';
      case 'transfer_out':
        return 'Transfer Keluar';
      case 'exchange_coins':
        return 'Tukar Koin';
      case 'scan_reward':
        return 'Reward Scan';
      case 'topup':
        return 'Top Up';
      default:
        return type;
    }
  }

  bool get isIncome {
    return ['transfer_in', 'scan_reward', 'topup'].contains(type.toLowerCase());
  }

  bool get isExpense {
    return ['transfer_out', 'exchange_coins'].contains(type.toLowerCase());
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