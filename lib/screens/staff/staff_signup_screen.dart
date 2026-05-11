import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/localization.dart';
import '../../widgets/language_picker.dart';

class StaffSignupScreen extends StatefulWidget {
  const StaffSignupScreen({super.key, required String initialRole});

  @override
  State<StaffSignupScreen> createState() => _StaffSignupScreenState();
}

class _StaffSignupScreenState extends State<StaffSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _hospitalIdController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _hospitalIdController.dispose();
    _departmentController.dispose();
    _employeeIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final db = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;

      final hospitalId = _hospitalIdController.text.trim().toUpperCase();
      final hospitalDoc = await db.collection('institutions').doc(hospitalId).get();

      if (!hospitalDoc.exists) {
        throw Exception('Invalid Hospital ID');
      }

      final hospitalData = hospitalDoc.data() ?? {};
      final hospitalName = (hospitalData['name'] ??
              hospitalData['institutionName'] ??
              'Hospital')
          .toString();

      final cred = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = cred.user!.uid;
      final now = FieldValue.serverTimestamp();

      await db.collection('users').doc(uid).set({
        'uid': uid,
        'name': _fullNameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'staff',
        'medicalRole': 'Staff',
        'institutionId': hospitalId,
        'institutionName': hospitalName,
        'department': _departmentController.text.trim(),
        'departmentName': _departmentController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'approvalStatus': 'pending',
        'createdAt': now,
        'updatedAt': now,
      });

      await db.collection('staff_requests').doc(uid).set({
        'uid': uid,
        'name': _fullNameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'staff',
        'medicalRole': 'Staff',
        'institutionId': hospitalId,
        'institutionName': hospitalName,
        'department': _departmentController.text.trim(),
        'departmentName': _departmentController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'status': 'pending',
        'approvalStatus': 'pending',
        'createdAt': now,
        'updatedAt': now,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff account created successfully')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String msg = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        msg = 'This email is already in use.';
      } else if (e.code == 'weak-password') {
        msg = 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email address.';
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

  InputDecoration _decoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: _decoration(label: label, icon: icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('staff_registration')),
        actions: [
          IconButton(
            tooltip: lang.translate('language'),
            onPressed: () => showLanguagePicker(context),
            icon: const Icon(Icons.language_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(_fullNameController, lang.translate('full_name'), Icons.person_outline_rounded),
                  _field(_hospitalIdController, lang.translate('hospital_id'), Icons.badge_outlined),
                  _field(_departmentController, lang.translate('department'), Icons.apartment_outlined),
                  _field(_employeeIdController, lang.translate('employee_id'), Icons.confirmation_number_outlined),
                  _field(_phoneController, lang.translate('phone'), Icons.phone_outlined, keyboardType: TextInputType.phone),
                  _field(_emailController, lang.translate('email'), Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  _field(_passwordController, lang.translate('password'), Icons.lock_outline_rounded, obscure: true),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _loading ? null : _signup,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(_loading ? lang.translate('loading') : lang.translate('create_account')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
