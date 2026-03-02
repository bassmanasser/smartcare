import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/constants.dart';
import 'patient/patient_signup_screen.dart';
import 'doctor/doctor_signup_screen.dart';
import 'parent/parent_signup_screen.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  bool _loading = false;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _setRoleAndGo(String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack("No logged in user. Please sign up again.");
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = user.uid;
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // ✅ لو role اتحدد قبل كده: ماينفعش يتغير (عشان الـRules بتمنع التغيير)
      final existing = await docRef.get();
      if (existing.exists) {
        final data = existing.data() as Map<String, dynamic>;
        final existingRole = data['role'];

        if (existingRole != null && existingRole.toString().trim().isNotEmpty) {
          // لو نفس الدور نكمل عادي ونروح لصفحة بياناته
          if (existingRole == role) {
            await _goToRoleScreen(role);
            return;
          }

          // لو مختلف: امنع التغيير
          _snack("Role already set to: $existingRole (cannot change).");
          if (mounted) setState(() => _loading = false);
          return;
        }
      }

      // ✅ Save role لأول مرة
      await docRef.set({
        "role": role,
        "profileCompleted": false,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      await _goToRoleScreen(role);
    } catch (e) {
      _snack("Failed to save role: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goToRoleScreen(String role) async {
    if (!mounted) return;

    if (role == "patient") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PatientSignUpScreen()),
      );
    } else if (role == "doctor") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DoctorSignupScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentSignUpScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = PETROL_DARK;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Select Role"),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: primary,
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 22),
            const Text(
              "Choose your role to continue",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              "This helps us show the correct home screen and profile form.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 26),

            _roleButton(
              text: "Patient",
              icon: Icons.favorite,
              color: primary,
              onTap: _loading ? null : () => _setRoleAndGo("patient"),
            ),
            const SizedBox(height: 14),

            _roleButton(
              text: "Doctor",
              icon: Icons.medical_services,
              color: primary,
              onTap: _loading ? null : () => _setRoleAndGo("doctor"),
            ),
            const SizedBox(height: 14),

            _roleButton(
              text: "Parent",
              icon: Icons.family_restroom,
              color: primary,
              onTap: _loading ? null : () => _setRoleAndGo("parent"),
            ),

            const SizedBox(height: 18),
            if (_loading) const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _roleButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
