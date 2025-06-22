// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecocycle_app/providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validasi sederhana agar tidak mengirim data kosong
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(backgroundColor: Colors.red, content: Text('Semua field wajib diisi.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Panggil fungsi register dari AuthProvider
      await Provider.of<AuthProvider>(context, listen: false).register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Jika baris di atas berhasil tanpa error, artinya registrasi sukses.
      // Kita tidak perlu navigasi ke HomeScreen secara manual.
      // Cukup tutup semua halaman di atas AuthWrapper.
      if (mounted) {
        // Perintah ini akan menutup semua halaman (register, login) sampai ke halaman paling dasar.
        // Saat itu terjadi, AuthWrapper akan otomatis menampilkan HomeScreen karena status login sudah berubah.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(e.toString().replaceFirst("Exception: ", "")),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF424242),
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               const Text('Create Account', style: TextStyle(color: Color(0xFF00BFA5), fontSize: 32, fontWeight: FontWeight.bold)),
               const SizedBox(height: 50),
               _buildTextField(controller: _nameController, hint: 'Full Name', icon: Icons.person, textInputType: TextInputType.name),
               const SizedBox(height: 20),
               _buildTextField(controller: _emailController, hint: 'Email', icon: Icons.email, textInputType: TextInputType.emailAddress),
               const SizedBox(height: 20),
               _buildTextField(controller: _passwordController, hint: 'Password (min. 8 karakter)', icon: Icons.lock, obscureText: true),
               const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) 
                      : const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon, bool obscureText = false, TextInputType textInputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: textInputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[800],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}