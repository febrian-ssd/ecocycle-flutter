// lib/services/mock_auth_service.dart

class MockAuthService {
  // Database user palsu
  final Map<String, dynamic> _fakeUsers = {
    'admin@ecocycle.com': {
      'password': 'password',
      'user': {'id': 1, 'name': 'Admin EcoCycle', 'email': 'admin@ecocycle.com', 'is_admin': true}
    },
    'user@ecocycle.com': {
      'password': 'password',
      'user': {'id': 2, 'name': 'User Biasa', 'email': 'user@ecocycle.com', 'is_admin': false}
    },
  };

  // Fungsi login palsu
  Future<Map<String, dynamic>> login(String email, String password) async {
    // Beri jeda 1 detik untuk simulasi loading jaringan
    await Future.delayed(const Duration(seconds: 1));

    if (_fakeUsers.containsKey(email)) {
      if (_fakeUsers[email]!['password'] == password) {
        return {
          'message': 'Login successful',
          'user': _fakeUsers[email]!['user'],
          'access_token': 'ini-adalah-fake-api-token-untuk-$email',
        };
      }
    }
    // Jika email atau password salah
    throw Exception('These credentials do not match our records.');
  }

  // Fungsi register palsu
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    if (_fakeUsers.containsKey(email)) {
      throw Exception('The email has already been taken.');
    }
    
    final newUser = {'id': 99, 'name': name, 'email': email, 'is_admin': false};
    
    return {
        'message': 'Registration successful',
        'user': newUser,
        'access_token': 'ini-adalah-fake-api-token-untuk-$email',
    };
  }
}