import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../auth/pending_approval_screen.dart';

class DoctorSignupScreen extends StatefulWidget {
  final String role;

  const DoctorSignupScreen({
    super.key,
    this.role = 'doctor',
  });

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _hospitalIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  bool get _showLicense =>
      widget.role.toLowerCase() == 'doctor' ||
      widget.role.toLowerCase() == 'nurse';

  @override
  void dispose() {
    _fullNameController.dispose();
    _hospitalIdController.dispose();
    _departmentController.dispose();
    _employeeIdController.dispose();
    _licenseNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _roleLabel {
    switch (widget.role.toLowerCase()) {
      case 'nurse':
        return 'Nurse';
      case 'staff':
        return 'Staff';
      default:
        return 'Doctor';
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final db = FirebaseFirestore.instance;
      final auth = FirebaseAuth.instance;

      final hospitalId = _hospitalIdController.text.trim().toUpperCase();

      final hospitalDoc =
          await db.collection('institutions').doc(hospitalId).get();

      if (!hospitalDoc.exists) {
        throw Exception('Invalid Hospital ID');
      }

      final hospitalData = hospitalDoc.data() ?? {};
      final hospitalName = (hospitalData['institutionName'] ?? '').toString();

      final cred = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = cred.user!.uid;
      final role = widget.role.toLowerCase();

      await db.collection('users').doc(uid).set({
        'uid': uid,
        'name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': role,
        'institutionId': hospitalId,
        'institutionName': hospitalName,
        'departmentName': _departmentController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'licenseNumber': _licenseNumberController.text.trim(),
        'approvalStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await db.collection('staff_requests').doc(uid).set({
        'uid': uid,
        'name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'institutionId': hospitalId,
        'institutionName': hospitalName,
        'departmentName': _departmentController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'licenseNumber': _licenseNumberController.text.trim(),
        'medicalRole': role,
        'staffRole': role,
        'approvalStatus': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PendingApprovalScreen(
            roleLabel: _roleLabel,
            hospitalName: hospitalName, role: '', status: '', institutionName: '',
          ),
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = 'Signup failed';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: Text('$_roleLabel Sign Up'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [PETROL_DARK, PETROL],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join as $_roleLabel',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your Hospital ID to join the institution. Your account will stay pending until the hospital admin approves it.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(_fullNameController, 'Full Name', Icons.person),
                  _field(_hospitalIdController, 'Hospital ID', Icons.numbers),
                  _field(_departmentController, 'Department', Icons.apartment),
                  _field(_employeeIdController, 'Employee ID', Icons.badge),
                  if (_showLicense)
                    _field(
                      _licenseNumberController,
                      'License Number',
                      Icons.verified,
                    ),
                  _field(_phoneController, 'Phone', Icons.phone),
                  _field(
                    _emailController,
                    'Email',
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _field(
                    _passwordController,
                    'Password',
                    Icons.lock,
                    obscure: true,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _signup,
                      icon: const Icon(Icons.how_to_reg),
                      label: Text(_loading ? 'Creating...' : 'Create Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PETROL_DARK,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
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