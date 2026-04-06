import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/localization.dart';
import 'admin/hospital_admin_signup_screen.dart';
import 'doctor/doctor_signup_screen.dart';
import 'parent/parent_signup_screen.dart';
import 'patient/patient_signup_screen.dart';
import 'staff/support_staff_signup_screen.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() =>
      _UserTypeSelectionScreenState();
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
          _snack(AppLocalizations.of(context).translate('role_locked'));
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

      Widget next;

      if (role == 'patient') {
        next = const PatientSignUpScreen();
      } else if (role == 'parent') {
        next = const ParentSignUpScreen();
      } else if (role == 'hospital_admin') {
        next = const HospitalAdminSignupScreen();
      } else {
        next = SupportStaffSignupScreen(initialRole: role);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => next),
      );
    } catch (e) {
      _snack('Failed to save role: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(tr.translate('choose_role')),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22.0),
        child: ListView(
          children: [
            const SizedBox(height: 28),
            Text(
              tr.translate('select_how_to_use'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr.translate('institution_workflow'),
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            _roleButton(
              text: tr.translate('patient'),
              subtitle: tr.translate('patient_desc'),
              icon: Icons.favorite,
              onTap: _loading ? null : () => _setRoleAndGo('patient'),
            ),
            const SizedBox(height: 14),

            _roleButton(
              text: tr.translate('parent'),
              subtitle: tr.translate('parent_desc'),
              icon: Icons.family_restroom,
              onTap: _loading ? null : () => _setRoleAndGo('parent'),
            ),
            const SizedBox(height: 14),

            _roleButton(
              text: tr.translate('hospital_admin'),
              subtitle: tr.translate('hospital_admin_desc'),
              icon: Icons.admin_panel_settings,
              onTap: _loading ? null : () => _setRoleAndGo('hospital_admin'),
            ),
            const SizedBox(height: 14),

            _roleButton(
              text: tr.translate('doctor'),
              subtitle: tr.translate('doctor_desc'),
              icon: Icons.medical_services,
              onTap: _loading ? null : () => _setRoleAndGo('doctor'),
            ),
            const SizedBox(height: 14),

            _roleButton(
              text: tr.translate('nurse'),
              subtitle: tr.translate('nurse_desc'),
              icon: Icons.local_hospital,
              onTap: _loading ? null : () => _setRoleAndGo('nurse'),
            ),
            const SizedBox(height: 14),

            _roleButton(
              text: tr.translate('triage_staff'),
              subtitle: tr.translate('triage_desc'),
              icon: Icons.route,
              onTap: _loading ? null : () => _setRoleAndGo('triage_staff'),
            ),
            const SizedBox(height: 14),

            _roleButton(
              text: tr.translate('support_staff'),
              subtitle: tr.translate('staff_desc'),
              icon: Icons.badge,
              onTap: _loading ? null : () => _setRoleAndGo('support_staff'),
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
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
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