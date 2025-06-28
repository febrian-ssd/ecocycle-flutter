// lib/models/user.dart
import 'package:ecocycle_app/utils/conversion_utils.dart';

class User {
  final int id;
  final String name;
  final String email;
  final bool isAdmin;
  final bool isActive;
  final double balanceRp;
  final int balanceCoins;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
    this.isActive = true,
    this.balanceRp = 0.0,
    this.balanceCoins = 0,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    bool parseIsAdmin(Map<String, dynamic> jsonData) {
      if (jsonData['is_admin'] != null) {
        return jsonData['is_admin'] is bool
            ? jsonData['is_admin']
            : jsonData['is_admin'] == 1;
      }
      if (jsonData['role'] != null) {
        return jsonData['role'] == 'admin';
      }
      return false;
    }

    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isAdmin: parseIsAdmin(json),
      isActive: json['is_active'] ?? json['active'] ?? true,
      balanceRp: ConversionUtils.toDouble(json['balance_rp'] ?? json['balance'] ?? 0),
      balanceCoins: ConversionUtils.toInt(json['balance_coins'] ?? json['coins'] ?? 0),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'is_admin': isAdmin,
      'is_active': isActive,
      'balance_rp': balanceRp,
      'balance_coins': balanceCoins,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get roleDisplay => isAdmin ? 'Administrator' : 'User';
  String get statusDisplay => isActive ? 'Active' : 'Inactive';

  String get formattedBalanceRp {
    return 'Rp ${balanceRp.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.'
    )}';
  }

  String get initials {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty) {
      return words[0][0].toUpperCase();
    }
    return 'U';
  }
}