import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get user => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signIn(String email, String password, BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return res.user;
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
      return null;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Unexpected error")),
      );
      return null;
    }
  }

  Future<User?> signUp({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return res.user;
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.message ?? "Signup failed")),
      );
      return null;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Unexpected error")),
      );
      return null;
    }
  }

  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
  }
}
