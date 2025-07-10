import 'package:buku_raya/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  bool _validateInput() {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage("Semua field harus diisi");
      return false;
    }

    if (!email.endsWith('@gmail.com')) {
      _showMessage("Email harus menggunakan domain @gmail.com");
      return false;
    }

    if (password != confirmPassword) {
      _showMessage("Kata sandi tidak cocok");
      return false;
    }

    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _registerWithEmailPassword() async {
  if (!_validateInput()) return;

  final username = _usernameController.text.trim();
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  setState(() => _isLoading = true);

  try {
    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final uid = userCredential.user?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'uid': uid,
      });
    }

    if (!mounted) return;
    _showMessage("Pendaftaran berhasil!");

  } on FirebaseAuthException catch (e) {
    String errorMsg = 'Terjadi kesalahan';
    if (e.code == 'email-already-in-use') {
      errorMsg = 'Email sudah digunakan';
    } else if (e.code == 'weak-password') {
      errorMsg = 'Password terlalu lemah (min. 6 karakter)';
    }

    if (!mounted) return;
    _showMessage(errorMsg);
    
  } catch (e) {
    if (!mounted) return;
    _showMessage("Error: ${e.toString()}");
    
  } finally {
    if (!mounted) return;
    setState(() => _isLoading = false);

    // 🎯 Pindah ke login page meskipun sukses atau gagal
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset("assets/images/iconbukuraya.png", height: 100),
                const SizedBox(height: 60),
                _buildTextField(_usernameController, "Nama Pengguna"),
                const SizedBox(height: 10),
                _buildTextField(_emailController, "Email"),
                const SizedBox(height: 10),
                _buildPasswordField(
                  controller: _passwordController,
                  label: "Kata Sandi",
                  obscure: _obscurePassword,
                  toggleObscure: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                const SizedBox(height: 10),
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: "Konfirmasi Kata Sandi",
                  obscure: _obscureConfirmPassword,
                  toggleObscure: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                ),
                const SizedBox(height: 20),
                _buildSubmitButton(),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Sudah punya akun?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Login()),
                        );
                      },
                      child: const Text("Masuk"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleObscure,
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.brown[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: _isLoading ? null : _registerWithEmailPassword,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text("Daftar", style: TextStyle(color: Colors.white)),
      ),
    );
  }}
  