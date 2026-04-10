import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/localization.dart';

class EmailAuthScreen extends StatefulWidget {
  final bool startAsLogin;

  const EmailAuthScreen({
    super.key,
    this.startAsLogin = true,
  });

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> _submit() async {
    final tr = AppLocalizations.of(context);
    final email = _email.text.trim();
    final pass = _password.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.translate('invalid_email_password'))),
      );
      return;
    }

    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: pass,
        );
      } else {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: pass,
        );
      }

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Authentication error';

      if (e.code == 'email-already-in-use') {
        msg = 'This email is already in use.';
      } else if (e.code == 'user-not-found') {
        msg = 'No user found with this email.';
      } else if (e.code == 'wrong-password') {
        msg = 'Wrong password.';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email address.';
      } else if (e.code == 'weak-password') {
        msg = 'Password is too weak.';
      } else if (e.code == 'invalid-credential') {
        msg = 'Invalid login credentials.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unexpected error. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final title = _isLogin ? tr.translate('login') : tr.translate('create_account');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.alternate_email_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: tr.translate('email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: tr.translate('password'),
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _loading ? null : _submit,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isLogin
                                  ? Icons.login_rounded
                                  : Icons.person_add_alt_1_rounded,
                            ),
                      label: Text(_loading ? 'Please wait...' : title),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() => _isLogin = !_isLogin),
                      child: Text(
                        _isLogin
                            ? tr.translate('dont_have_account')
                            : tr.translate('already_have_account'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}