// lib/models/user.dart

class User {
  final int id;
  final String name;
  final String email;
  final bool isAdmin;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.isAdmin,
  });

  // Factory constructor untuk membuat User dari JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      // 'is_admin' dari Laravel adalah 0 atau 1, kita ubah jadi true/false
      isAdmin: json['is_admin'] == 1 || json['is_admin'] == true,
    );
  }

  // Method untuk mengubah User menjadi JSON (untuk disimpan di SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'is_admin': isAdmin,
    };
  }
}