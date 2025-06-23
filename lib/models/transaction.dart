// lib/models/transaction.dart

class Transaction {
  final int id;
  final String type;
  final double? amountRp;
  final int? amountCoins;
  final String description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.type,
    this.amountRp,
    this.amountCoins,
    required this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int,
      type: json['type'] as String,
      amountRp: json['amount_rp'] != null 
          ? double.tryParse(json['amount_rp'].toString()) 
          : null,
      amountCoins: json['amount_coins'] != null 
          ? int.tryParse(json['amount_coins'].toString()) 
          : null,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
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
  bool get isIncome {
    return type == 'topup' || 
           type == 'manual_topup' || 
           type == 'scan_reward' ||
           (amountRp != null && amountRp! > 0) ||
           (amountCoins != null && amountCoins! > 0);
  }

  bool get isExpense {
    return type == 'transfer_out' ||
           (amountRp != null && amountRp! < 0);
  }

  String get displayAmount {
    if (amountRp != null && amountRp != 0) {
      return 'Rp ${amountRp!.abs().toStringAsFixed(0)}';
    } else if (amountCoins != null && amountCoins != 0) {
      return '${amountCoins!.abs()} koin';
    }
    return '-';
  }

  String get typeDisplayName {
    switch (type) {
      case 'topup':
      case 'manual_topup':
        return 'Top Up Saldo';
      case 'transfer_out':
        return 'Transfer Keluar';
      case 'coin_exchange_to_rp':
        return 'Tukar Koin';
      case 'scan_reward':
        return 'Reward Scan';
      default:
        return 'Transaksi';
    }
  }
}