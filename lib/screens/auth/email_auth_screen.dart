import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../utils/constants.dart';
import '../patient/patient_signup_screen.dart';
import '../doctor/doctor_signup_screen.dart';
import '../parent/parent_signup_screen.dart';

class EmailAuthScreen extends StatefulWidget {
  final String role;          // patient | doctor | parent
  final bool startAsLogin;    // true=login , false=signup

  const EmailAuthScreen({
    super.key,
    required this.role,
    this.startAsLogin = true,
  });

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = FirebaseAuth.instance;

  late bool _isLogin;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.startAsLogin;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Widget _nextProfileScreen() {
    if (widget.role == "patient") return const PatientSignUpScreen();
    if (widget.role == "doctor") return const DoctorSignupScreen();
    return const ParentSignUpScreen();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _password.text.trim();

    if (email.isEmpty || pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password (min 6 chars).')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isLogin) {
        // ✅ Login
        await _auth.signInWithEmailAndPassword(email: email, password: pass);

        if (!mounted) return;
        Navigator.pop(context); // Main.dart هيحوّل لHome حسب الدور من Firestore
      } else {
        // ✅ Signup (create auth account)
        await _auth.createUserWithEmailAndPassword(email: email, password: pass);

        if (!mounted) return;

        // ✅ بعد إنشاء الحساب: ادخلي مباشرة صفحة "Complete Profile" حسب الدور
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => _nextProfileScreen()),
          (r) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Authentication error';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unexpected error. Try again.')),
      );
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? "Login" : "Create Account";

    return Scaffold(
      appBar: AppBar(
        title: Text("$title (${widget.role.toUpperCase()})"),
        backgroundColor: PETROL_DARK,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: PETROL_DARK, foregroundColor: Colors.white),
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 14),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? "Don't have an account? Sign up" : "Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}
