import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../user_type_selection_screen.dart';
import '../../utils/constants.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = FirebaseAuth.instance;

  bool _isLogin = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _password.text.trim();

    if (email.isEmpty || pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Enter a valid email and password (min 6 chars).'),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      UserCredential cred;
      if (_isLogin) {
        cred = await _auth.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      } else {
        cred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
      }

      if (!mounted) return;

      // بعد التسجيل/الدخول → نسيب SplashScreen يشوف role
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const UserTypeSelectionScreen(),
        ),
        (r) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Authentication error';
      if (e.code == 'user-not-found') msg = 'No user found for this email.';
      if (e.code == 'wrong-password') msg = 'Wrong password.';
      if (e.code == 'email-already-in-use') msg = 'Email already in use.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isLogin ? 'Login' : 'Sign Up';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: PETROL_DARK,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.lock_open, size: 80, color: PETROL),
                const SizedBox(height: 16),
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                _loading
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PETROL,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(
                              _isLogin
                                  ? "Don't have an account? Sign Up"
                                  : 'Already have an account? Login',
                            ),
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
}
