import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../widgets/language_picker.dart';
import '../admin/admin_home_screen.dart';
import '../doctor/doctor_home_screen.dart';
import '../nurse/nurse_home_screen.dart';
import '../parent/parent_home_screen.dart';
import '../staff/staff_home_screen.dart';
import '../patient/patient_home_screen.dart';
import 'pending_approval_screen.dart';
import '../../models/doctor.dart';
import '../../models/patient.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final auth = FirebaseAuth.instance;
      final db = FirebaseFirestore.instance;

      final cred = await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = cred.user!.uid;
      final userDoc = await db.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('User profile not found.');
      }

      final data = userDoc.data() ?? {};
      final role = (data['role'] ?? '').toString().toLowerCase();
      final approvalStatus = (data['approvalStatus'] ?? 'approved').toString();

      if (approvalStatus == 'pending') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PendingApprovalScreen(
              roleLabel: role.isEmpty ? 'Account' : role,
              hospitalName: (data['institutionName'] ?? '').toString(), role: '', status: '', institutionName: '',
            ),
          ),
        );
        return;
      }

      if (!mounted) return;

      switch (role) {
        case 'hospital_admin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
          );
          break;

        case 'doctor':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DoctorHomeScreen(doctor: Doctor.fromJson({...data, 'id': uid}))),
          );
          break;

        case 'nurse':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const NurseHomeScreen()),
          );
          break;

        case 'staff':
        case 'support_staff':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StaffHomeScreen()),
          );
          break;

        case 'patient':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => PatientHomeScreen(patient: Patient.fromJson({...data, 'id': uid}))),
          );
          break;

        case 'parent':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ParentHomeScreen(parent: data)),
          );
          break;

        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unknown account role.')),
          );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Login failed';
      if (e.code == 'user-not-found') {
        msg = 'No account found for this email.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        msg = 'Invalid email or password.';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email format.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: Text(lang.translate('login')),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: lang.translate('language'),
            onPressed: () => showLanguagePicker(context),
            icon: const Icon(Icons.language_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 40),
                const Icon(
                  Icons.favorite,
                  color: PETROL_DARK,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  lang.translate('welcome_back'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: PETROL_DARK,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lang.translate('choose_login_or_signup'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _field(
                        _emailController,
                        lang.translate('email'),
                        Icons.email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      _field(
                        _passwordController,
                        lang.translate('password'),
                        Icons.lock,
                        obscure: true,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PETROL_DARK,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(_loading ? lang.translate('loading') : lang.translate('login')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          icon: Icon(icon, color: PETROL_DARK),
          labelText: label,
          border: InputBorder.none,
        ),
      ),
    );
  }
}
