import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/hospital_id_service.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import 'admin_home_screen.dart';

class HospitalAdminSignupScreen extends StatefulWidget {
  const HospitalAdminSignupScreen({super.key});

  @override
  State<HospitalAdminSignupScreen> createState() =>
      _HospitalAdminSignupScreenState();
}

class _HospitalAdminSignupScreenState extends State<HospitalAdminSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _institutionName = TextEditingController();
  final _institutionAddress = TextEditingController();
  final _institutionCity = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _institutionName.dispose();
    _institutionAddress.dispose();
    _institutionCity.dispose();
    super.dispose();
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
      final hospitalId =
          HospitalIdService.generateHospitalId(_institutionName.text.trim());

      final institutionData = {
        'hospitalId': hospitalId,
        'institutionName': _institutionName.text.trim(),
        'institutionAddress': _institutionAddress.text.trim(),
        'institutionCity': _institutionCity.text.trim(),
        'adminUid': user.uid,
        'adminName': _name.text.trim(),
        'adminEmail': user.email ?? '',
        'adminPhone': _phone.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('institutions')
          .doc(hospitalId)
          .set(institutionData);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': _name.text.trim(),
        'email': user.email ?? '',
        'phone': _phone.text.trim(),
        'role': 'hospital_admin',
        'institutionId': hospitalId,
        'institutionName': _institutionName.text.trim(),
        'institutionAddress': _institutionAddress.text.trim(),
        'institutionCity': _institutionCity.text.trim(),
        'approvalStatus': 'approved',
        'profileCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.translate('hospital_admin')),
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
                controller: _name,
                decoration: InputDecoration(
                  labelText: tr.translate('full_name'),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                decoration: InputDecoration(
                  labelText: tr.translate('phone'),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _institutionName,
                decoration: InputDecoration(
                  labelText: tr.translate('institution_name'),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _institutionAddress,
                decoration: InputDecoration(
                  labelText: tr.translate('institution_address'),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _institutionCity,
                decoration: InputDecoration(
                  labelText: tr.translate('institution_city'),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
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
                  _loading
                      ? '...'
                      : tr.translate('save_continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}