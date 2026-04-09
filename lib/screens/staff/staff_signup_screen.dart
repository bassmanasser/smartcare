import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Registration'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F5C63), Color(0xFF2A8C95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.how_to_reg_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Staff Registration',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Join your hospital as staff using the hospital ID.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.92),
                            fontSize: 13.5,
                          ),
                        ),
                      ],
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
                  _field(_fullNameController, 'Full Name', Icons.person_outline_rounded),
                  _field(_hospitalIdController, 'Hospital ID', Icons.badge_outlined),
                  _field(_departmentController, 'Department', Icons.apartment_outlined),
                  _field(_employeeIdController, 'Employee ID', Icons.confirmation_number_outlined),
                  _field(_phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
                  _field(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  _field(_passwordController, 'Password', Icons.lock_outline_rounded, obscure: true),
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
                      label: Text(_loading ? 'Creating...' : 'Create Account'),
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