import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/hospital_id_service.dart';
import 'admin_home_screen.dart';

class HospitalAdminSignupScreen extends StatefulWidget {
  const HospitalAdminSignupScreen({super.key});

  @override
  State<HospitalAdminSignupScreen> createState() =>
      _HospitalAdminSignupScreenState();
}

class _HospitalAdminSignupScreenState extends State<HospitalAdminSignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _adminNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _institutionNameController =
      TextEditingController();
  final TextEditingController _institutionAddressController =
      TextEditingController();
  final TextEditingController _institutionCityController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _adminNameController.dispose();
    _phoneController.dispose();
    _institutionNameController.dispose();
    _institutionAddressController.dispose();
    _institutionCityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authenticated user found')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final institutionName = _institutionNameController.text.trim();
      final institutionAddress = _institutionAddressController.text.trim();
      final institutionCity = _institutionCityController.text.trim();
      final adminName = _adminNameController.text.trim();
      final phone = _phoneController.text.trim();
      final description = _descriptionController.text.trim();

      final hospitalId = HospitalIdService.generateHospitalId(institutionName);
      final now = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('institutions')
          .doc(hospitalId)
          .set({
        'hospitalId': hospitalId,
        'institutionId': hospitalId,
        'name': institutionName,
        'institutionName': institutionName,
        'address': institutionAddress,
        'institutionAddress': institutionAddress,
        'city': institutionCity,
        'institutionCity': institutionCity,
        'description': description,
        'adminUid': user.uid,
        'adminName': adminName,
        'adminEmail': user.email ?? '',
        'adminPhone': phone,
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': adminName,
        'fullName': adminName,
        'email': user.email ?? '',
        'phone': phone,
        'role': 'hospital_admin',
        'approvalStatus': 'approved',
        'profileCompleted': true,
        'institutionId': hospitalId,
        'institutionName': institutionName,
        'institutionAddress': institutionAddress,
        'institutionCity': institutionCity,
        'updatedAt': now,
        'createdAt': now,
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete hospital setup: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Setup'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _adminNameController,
              decoration: _decoration(
                label: 'Admin Full Name',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: _decoration(
                label: 'Phone Number',
                icon: Icons.phone_outlined,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _institutionNameController,
              decoration: _decoration(
                label: 'Hospital Name',
                icon: Icons.business_outlined,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _institutionCityController,
              decoration: _decoration(
                label: 'City',
                icon: Icons.location_city_outlined,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _institutionAddressController,
              maxLines: 2,
              decoration: _decoration(
                label: 'Address',
                icon: Icons.location_on_outlined,
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _decoration(
                label: 'Description',
                icon: Icons.description_outlined,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(_loading ? 'Saving...' : 'Complete Setup'),
            ),
          ],
        ),
      ),
    );
  }
}