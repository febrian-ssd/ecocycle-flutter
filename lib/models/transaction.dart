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
      id: json['id'],
      type: json['type'],
      amountRp: json['amount_rp'] != null ? double.parse(json['amount_rp']) : null,
      amountCoins: json['amount_coins'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}