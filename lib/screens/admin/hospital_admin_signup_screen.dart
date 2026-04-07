import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import 'admin_home_screen.dart';

class HospitalAdminSignupScreen extends StatefulWidget {
  const HospitalAdminSignupScreen({super.key});

  @override
  State<HospitalAdminSignupScreen> createState() =>
      _HospitalAdminSignupScreenState();
}

class _HospitalAdminSignupScreenState
    extends State<HospitalAdminSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _hospitalCityController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    _hospitalCityController.dispose();
    _adminNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _generateHospitalId(String hospitalName) {
    final clean = hospitalName
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final prefix = clean.length >= 4 ? clean.substring(0, 4) : clean;
    final millis = DateTime.now().millisecondsSinceEpoch.toString();
    final suffix = millis.substring(millis.length - 6);
    return '${prefix}H$suffix';
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final auth = FirebaseAuth.instance;
      final db = FirebaseFirestore.instance;

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final hospitalName = _hospitalNameController.text.trim();

      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user!.uid;
      final institutionId = _generateHospitalId(hospitalName);

      await db.collection('institutions').doc(institutionId).set({
        'institutionId': institutionId,
        'institutionName': hospitalName,
        'institutionAddress': _hospitalAddressController.text.trim(),
        'institutionCity': _hospitalCityController.text.trim(),
        'adminUid': uid,
        'adminName': _adminNameController.text.trim(),
        'adminPhone': _phoneController.text.trim(),
        'adminEmail': email,
        'accountType': 'hospital_admin',
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await db.collection('users').doc(uid).set({
        'uid': uid,
        'name': _adminNameController.text.trim(),
        'email': email,
        'phone': _phoneController.text.trim(),
        'role': 'hospital_admin',
        'institutionId': institutionId,
        'institutionName': hospitalName,
        'institutionAddress': _hospitalAddressController.text.trim(),
        'institutionCity': _hospitalCityController.text.trim(),
        'approvalStatus': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hospital created successfully. ID: $institutionId')),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
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
        SnackBar(content: Text('Error: $e')),
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
        title: const Text('Hospital Admin Sign Up'),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Hospital Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'A unique Hospital ID will be generated automatically for doctors, nurses, and staff.',
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
                  _field(
                    _hospitalNameController,
                    'Hospital Name',
                    Icons.local_hospital,
                  ),
                  _field(
                    _hospitalAddressController,
                    'Hospital Address',
                    Icons.location_on,
                    maxLines: 2,
                  ),
                  _field(
                    _hospitalCityController,
                    'City',
                    Icons.location_city,
                  ),
                  _field(
                    _adminNameController,
                    'Admin Full Name',
                    Icons.person,
                  ),
                  _field(
                    _phoneController,
                    'Phone',
                    Icons.phone,
                  ),
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
                      icon: const Icon(Icons.app_registration),
                      label: Text(_loading ? 'Creating...' : 'Create Hospital Account'),
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
    int maxLines = 1,
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
        maxLines: maxLines,
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