import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'admin/admin_home_screen.dart';
import 'doctor/doctor_signup_screen.dart';
import 'parent/parent_signup_screen.dart';
import 'patient/patient_signup_screen.dart';

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
      _snack('No logged in user. Please sign up again.');
      return;
    }

    setState(() => _loading = true);

    try {
      final uid = user.uid;
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final existing = await docRef.get();

      if (existing.exists) {
        final data = existing.data() as Map<String, dynamic>;
        final existingRole = (data['role'] ?? '').toString().trim();

        if (existingRole.isNotEmpty && existingRole != role) {
          _snack('Role already set to $existingRole and cannot be changed.');
          if (mounted) setState(() => _loading = false);
          return;
        }
      }

      await docRef.set({
        'role': role,
        'profileCompleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      if (role == 'patient') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PatientSignUpScreen()),
        );
      } else if (role == 'parent') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParentSignUpScreen()),
        );
      } else if (role == 'hospital_admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DoctorSignupScreen()),
        );
      }
    } catch (e) {
      _snack('Failed to save role: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Choose Role'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22.0),
        child: ListView(
          children: [
            const SizedBox(height: 28),
            const Text(
              'Select how you want to use SmartCare',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Medical staff are now registered as part of a hospital / institution workflow.',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            _roleButton(
              text: 'Patient',
              subtitle: 'Vitals, alerts, QR, care team',
              icon: Icons.favorite,
              onTap: _loading ? null : () => _setRoleAndGo('patient'),
            ),
            const SizedBox(height: 14),
            _roleButton(
              text: 'Medical Staff',
              subtitle: 'Doctor / Nurse / Triage / Hospital Staff',
              icon: Icons.medical_services,
              onTap: _loading ? null : () => _setRoleAndGo('doctor'),
            ),
            const SizedBox(height: 14),
            _roleButton(
              text: 'Hospital Admin',
              subtitle: 'Approve staff and manage institution flow',
              icon: Icons.admin_panel_settings,
              onTap: _loading ? null : () => _setRoleAndGo('hospital_admin'),
            ),
            const SizedBox(height: 14),
            _roleButton(
              text: 'Parent',
              subtitle: 'Follow patient status and emergency updates',
              icon: Icons.family_restroom,
              onTap: _loading ? null : () => _setRoleAndGo('parent'),
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
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LIGHT_BG,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PETROL.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: PETROL_DARK,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}