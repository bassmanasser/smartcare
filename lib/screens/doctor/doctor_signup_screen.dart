import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _hospitalIdController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _loading = false;

  bool get _showLicense {
    final role = widget.role.toLowerCase();
    return role == 'doctor' || role == 'nurse';
  }

  String get _roleLabel {
    switch (widget.role.toLowerCase()) {
      case 'nurse':
        return 'Nurse';
      case 'staff':
      case 'support_staff':
        return 'Staff';
      default:
        return 'Doctor';
    }
  }

  String get _normalizedRole {
    switch (widget.role.toLowerCase()) {
      case 'staff':
      case 'support_staff':
        return 'staff';
      case 'nurse':
        return 'nurse';
      default:
        return 'doctor';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _hospitalIdController.dispose();
    _departmentController.dispose();
    _employeeIdController.dispose();
    _licenseNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authenticated user found.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final db = FirebaseFirestore.instance;
      final hospitalId = _hospitalIdController.text.trim().toUpperCase();

      final hospitalDoc = await db.collection('institutions').doc(hospitalId).get();

      if (!hospitalDoc.exists) {
        throw Exception('Invalid Hospital ID');
      }

      final hospitalData = hospitalDoc.data() ?? {};
      final hospitalName =
          (hospitalData['name'] ?? hospitalData['institutionName'] ?? 'Hospital')
              .toString();

      final role = _normalizedRole;
      final now = FieldValue.serverTimestamp();

      final userPayload = {
        'uid': user.uid,
        'name': _fullNameController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'email': user.email ?? '',
        'phone': _phoneController.text.trim(),
        'role': role,
        'medicalRole': _roleLabel,
        'institutionId': hospitalId,
        'institutionName': hospitalName,
        'department': _departmentController.text.trim(),
        'departmentName': _departmentController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'licenseNumber': _showLicense ? _licenseNumberController.text.trim() : '',
        'approvalStatus': 'pending',
        'profileCompleted': true,
        'createdAt': now,
        'updatedAt': now,
      };

      await db.collection('users').doc(user.uid).set(
            userPayload,
            SetOptions(merge: true),
          );

      await db.collection('staff_requests').doc(user.uid).set(
            {
              ...userPayload,
              'status': 'pending',
            },
            SetOptions(merge: true),
          );

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => PendingApprovalScreen(
            roleLabel: _roleLabel,
            hospitalName: hospitalName,
            role: role,
            status: 'pending',
            institutionName: hospitalName,
          ),
        ),
        (_) => false,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
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
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator ??
            (v) => v == null || v.trim().isEmpty ? 'Required' : null,
        decoration: _decoration(label: label, icon: icon),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_roleLabel Registration'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _field(
                    _fullNameController,
                    'Full Name',
                    Icons.person_outline_rounded,
                  ),
                  _field(
                    _hospitalIdController,
                    'Hospital ID',
                    Icons.badge_outlined,
                  ),
                  _field(
                    _departmentController,
                    'Department',
                    Icons.apartment_outlined,
                  ),
                  _field(
                    _employeeIdController,
                    'Employee ID',
                    Icons.confirmation_number_outlined,
                  ),
                  if (_showLicense)
                    _field(
                      _licenseNumberController,
                      'License Number',
                      Icons.verified_user_outlined,
                    ),
                  _field(
                    _phoneController,
                    'Phone Number',
                    Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _loading ? null : _signup,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline_rounded),
                    label: Text(_loading ? 'Saving...' : 'Submit Registration'),
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