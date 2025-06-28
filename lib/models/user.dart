// lib/models/user.dart - DIRUBAH: Logika role diubah ke isAdmin
import 'package:ecocycle_app/utils/conversion_utils.dart';

class User {
  final int id;
  final String name;
  final String email;
  final bool isAdmin; // DIRUBAH: dari String role ke bool isAdmin
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

  // Factory constructor untuk membuat User dari JSON
  factory User.fromJson(Map<String, dynamic> json) {
    // DIRUBAH: Logika untuk menentukan isAdmin dibuat lebih kuat
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

  // Helper methods untuk parsing
  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Method untuk mengubah User menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'is_admin': isAdmin, // DIRUBAH: Menggunakan is_admin
      'is_active': isActive,
      'balance_rp': balanceRp,
      'balance_coins': balanceCoins,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // DIRUBAH: Getter disesuaikan dengan properti isAdmin
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

  // DIRUBAH: Logika perizinan disesuaikan dengan isAdmin
  bool canAccessFeature(String feature) {
    if (isAdmin) {
      // Admin bisa akses semua fitur
      return true;
    } else {
      // Perizinan untuk user biasa
      switch (feature) {
        case 'admin_panel':
        case 'user_management':
        case 'dropbox_management':
        case 'approve_topups':
        case 'system_stats':
          return false;
        case 'user_wallet':
        case 'scan_qr':
        case 'transfer_money':
        case 'exchange_coins':
        case 'request_topup':
        default:
          return true;
      }
    }
  }

  // DIRUBAH: Menu yang tersedia disesuaikan dengan isAdmin
  List<String> getAvailableMenuItems() {
    if (isAdmin) {
      return [
        'dashboard', 'users', 'dropboxes', 'topup_requests',
        'transactions', 'history', 'system', 'profile',
      ];
    } else {
      return ['home', 'wallet', 'scan', 'history', 'map', 'profile'];
    }
  }

  // Copy with method untuk updating user data
  User copyWith({
    int? id,
    String? name,
    String? email,
    bool? isAdmin,
    bool? isActive,
    double? balanceRp,
    int? balanceCoins,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      isActive: isActive ?? this.isActive,
      balanceRp: balanceRp ?? this.balanceRp,
      balanceCoins: balanceCoins ?? this.balanceCoins,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, isAdmin: $isAdmin, isActive: $isActive}';
  }
}