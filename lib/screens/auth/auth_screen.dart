import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/constants.dart';
import '../user_type_selection_screen.dart';
import 'welcome_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text.trim();

    if (email.isEmpty || !email.contains("@")) {
      _snack("Enter a valid email");
      return;
    }
    if (pass.length < 6) {
      _snack("Password must be at least 6 characters");
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);

        // ✅ لا نعمل Navigator للهوم هنا
        // الـAuthWrapper في main.dart هيحول تلقائيًا للـHome بعد نجاح الدخول
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);

        if (!mounted) return;
        // ✅ بعد SignUp: نسأل Role
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const UserTypeSelectionScreen()),
          (r) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? (_isLogin ? "Login Failed" : "Signup Failed"));
    } catch (_) {
      _snack("Unexpected error");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = PETROL_DARK; // نفس لون التصميم بتاعك

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        title: Text(_isLogin ? "Login" : "Sign Up"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 30),
              CircleAvatar(
                radius: 42,
                backgroundColor: primary,
                child: const Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 34),

              // Email
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email Address",
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: primary),
                  hintText: "example@email.com",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Password
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password",
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.lock, color: primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 26),

              // Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isLogin ? "Login" : "Sign Up",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // Toggle text
              GestureDetector(
                onTap: _loading ? null : () => setState(() => _isLogin = !_isLogin),
                child: Text(
                  _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Login",
                  style: const TextStyle(color: Colors.purple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
