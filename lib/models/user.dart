// lib/models/user.dart - Enhanced with Role Management

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final double balanceRp;
  final int balanceCoins;
  final DateTime? createdAt;

  // Role constants
  static const String ROLE_ADMIN = 'admin';
  static const String ROLE_USER = 'user';

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.balanceRp = 0.0,
    this.balanceCoins = 0,
    this.createdAt,
  });

  // Factory constructor untuk membuat User dari JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? ROLE_USER,
      isActive: json['is_active'] ?? json['active'] ?? true,
      balanceRp: _parseDouble(json['balance_rp'] ?? json['balance'] ?? 0),
      balanceCoins: _parseInt(json['balance_coins'] ?? json['coins'] ?? 0),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  // Helper methods for parsing
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  // Method untuk mengubah User menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_active': isActive,
      'balance_rp': balanceRp,
      'balance_coins': balanceCoins,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  // Role checking methods
  bool get isAdmin => role == ROLE_ADMIN;
  bool get isUser => role == ROLE_USER;
  
  bool hasRole(String checkRole) => role == checkRole;
  
  bool hasAnyRole(List<String> roles) => roles.contains(role);

  // Display helpers
  String get roleDisplay {
    switch (role) {
      case ROLE_ADMIN:
        return 'Administrator';
      case ROLE_USER:
        return 'User';
      default:
        return 'Unknown';
    }
  }

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

  // Permission checking (can be extended based on your needs)
  bool canAccessFeature(String feature) {
    switch (feature) {
      case 'admin_panel':
        return isAdmin;
      case 'user_management':
        return isAdmin;
      case 'dropbox_management':
        return isAdmin;
      case 'approve_topups':
        return isAdmin;
      case 'system_stats':
        return isAdmin;
      case 'user_wallet':
        return isUser || isAdmin;
      case 'scan_qr':
        return isUser;
      case 'transfer_money':
        return isUser;
      case 'exchange_coins':
        return isUser;
      case 'request_topup':
        return isUser;
      default:
        return true; // Basic features available to all authenticated users
    }
  }

  // Get available menu items based on role
  List<String> getAvailableMenuItems() {
    if (isAdmin) {
      return [
        'dashboard',
        'users',
        'dropboxes',
        'topup_requests',
        'transactions',
        'history',
        'system',
        'profile',
      ];
    } else if (isUser) {
      return [
        'home',
        'wallet',
        'scan',
        'history',
        'map',
        'profile',
      ];
    }
    return ['profile'];
  }

  // Copy with method for updating user data
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? role,
    bool? isActive,
    double? balanceRp,
    int? balanceCoins,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      balanceRp: balanceRp ?? this.balanceRp,
      balanceCoins: balanceCoins ?? this.balanceCoins,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name, email: $email, role: $role, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}