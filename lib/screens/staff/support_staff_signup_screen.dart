import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../utils/localization.dart';

class SupportStaffSignupScreen extends StatefulWidget {
  final String initialRole;

  const SupportStaffSignupScreen({
    super.key,
    required this.initialRole,
  });

  @override
  State<SupportStaffSignupScreen> createState() =>
      _SupportStaffSignupScreenState();
}

class _SupportStaffSignupScreenState extends State<SupportStaffSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _hospitalId = TextEditingController();
  final _name = TextEditingController();
  final _department = TextEditingController();
  final _employeeId = TextEditingController();
  final _licenseNumber = TextEditingController();
  final _workPhone = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _hospitalId.dispose();
    _name.dispose();
    _department.dispose();
    _employeeId.dispose();
    _licenseNumber.dispose();
    _workPhone.dispose();
    super.dispose();
  }

  String _roleLabel(String role, AppLocalizations tr) {
    switch (role) {
      case 'doctor':
        return tr.translate('doctor');
      case 'nurse':
        return tr.translate('nurse');
      case 'triage_staff':
        return tr.translate('triage_staff');
      default:
        return tr.translate('support_staff');
    }
  }

  Future<void> _save() async {
    final tr = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.translate('please_fill_required'))),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final hospitalId = _hospitalId.text.trim().toUpperCase();

      final institutionDoc = await FirebaseFirestore.instance
          .collection('institutions')
          .doc(hospitalId)
          .get();

      if (!institutionDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.translate('institution_not_found'))),
        );
        setState(() => _loading = false);
        return;
      }

      final institutionData = institutionDoc.data() ?? {};

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': _name.text.trim(),
        'email': user.email ?? '',
        'phone': _workPhone.text.trim(),
        'role': widget.initialRole,
        'medicalRole': widget.initialRole,
        'departmentName': _department.text.trim(),
        'employeeId': _employeeId.text.trim(),
        'licenseNumber': _licenseNumber.text.trim(),
        'institutionId': hospitalId,
        'institutionName': institutionData['institutionName'] ?? '',
        'approvalStatus': 'pending',
        'profileCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('staff_requests')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'name': _name.text.trim(),
        'email': user.email ?? '',
        'role': widget.initialRole,
        'medicalRole': widget.initialRole,
        'departmentName': _department.text.trim(),
        'employeeId': _employeeId.text.trim(),
        'licenseNumber': _licenseNumber.text.trim(),
        'institutionId': hospitalId,
        'institutionName': institutionData['institutionName'] ?? '',
        'approvalStatus': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.translate('profile_saved'))),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_roleLabel(widget.initialRole, tr)),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _hospitalId,
                decoration: InputDecoration(
                  labelText: tr.translate('hospital_id'),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: tr.translate('full_name'),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _department,
                decoration: InputDecoration(
                  labelText: tr.translate('department'),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _employeeId,
                decoration: InputDecoration(
                  labelText: tr.translate('employee_id'),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _licenseNumber,
                decoration: InputDecoration(
                  labelText: tr.translate('license_number'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _workPhone,
                decoration: InputDecoration(
                  labelText: tr.translate('work_phone'),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PETROL_DARK,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _loading ? '...' : tr.translate('save_continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}