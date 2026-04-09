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

class _HospitalAdminSignupScreenState extends State<HospitalAdminSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _hospitalNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _hospitalNameController.dispose();
    _ownerNameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _generateInstitutionId(String hospitalName) {
    final cleaned = hospitalName
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '');

    final short = cleaned.isEmpty
        ? 'HOSP'
        : (cleaned.length >= 4 ? cleaned.substring(0, 4) : cleaned);

    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final millis = (now.millisecond + now.second).toString().padLeft(3, '0');

    return 'HOSP-$short-$year$month$day-$millis';
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: PETROL_DARK, width: 1.3),
      ),
    );
  }

  Future<void> _signupHospital() async {
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
      final institutionId = _generateInstitutionId(hospitalName);
      final now = FieldValue.serverTimestamp();

      final institutionPayload = {
        'institutionId': institutionId,
        'institutionName': hospitalName,
        'institutionCity': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': email,
        'ownerUid': uid,
        'ownerName': _ownerNameController.text.trim(),
        'role': 'hospital',
        'createdAt': now,
        'updatedAt': now,
      };

      await db.collection('institutions').doc(institutionId).set(institutionPayload);

      await db.collection('users').doc(uid).set({
        'uid': uid,
        'name': _ownerNameController.text.trim(),
        'email': email,
        'phone': _phoneController.text.trim(),
        'role': 'hospital',
        'institutionId': institutionId,
        'institutionName': hospitalName,
        'institutionCity': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'createdAt': now,
        'updatedAt': now,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hospital registered successfully. ID: $institutionId'),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? 'Authentication error';
      if (e.code == 'email-already-in-use') {
        msg = 'This email is already in use';
      } else if (e.code == 'weak-password') {
        msg = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        msg = 'Invalid email address';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      debugPrint('hospital signup error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        backgroundColor: LIGHT_BG,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Hospital Registration',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [PETROL_DARK, PETROL],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create Main Hospital Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'A unique Hospital ID will be generated automatically after registration.',
                      style: TextStyle(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _hospitalNameController,
                decoration: _decoration(
                  label: 'Hospital Name',
                  icon: Icons.business_rounded,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerNameController,
                decoration: _decoration(
                  label: 'Account Owner Name',
                  icon: Icons.person_rounded,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: _decoration(
                  label: 'City',
                  icon: Icons.location_city_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: _decoration(
                  label: 'Address',
                  icon: Icons.place_rounded,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: _decoration(
                  label: 'Phone',
                  icon: Icons.phone_rounded,
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: _decoration(
                  label: 'Hospital Email',
                  icon: Icons.email_rounded,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _decoration(
                  label: 'Password',
                  icon: Icons.lock_rounded,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 6) return 'At least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _signupHospital,
                  icon: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.app_registration_rounded),
                  label: Text(_loading ? 'Creating...' : 'Create Hospital Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PETROL_DARK,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}