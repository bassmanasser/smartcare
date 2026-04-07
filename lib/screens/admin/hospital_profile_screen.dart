import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants.dart';

class HospitalProfileScreen extends StatefulWidget {
  const HospitalProfileScreen({super.key});

  @override
  State<HospitalProfileScreen> createState() => _HospitalProfileScreenState();
}

class _HospitalProfileScreenState extends State<HospitalProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _hospitalName = TextEditingController();
  final TextEditingController _hospitalAddress = TextEditingController();
  final TextEditingController _hospitalCity = TextEditingController();
  final TextEditingController _adminName = TextEditingController();
  final TextEditingController _adminPhone = TextEditingController();
  final TextEditingController _adminEmail = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String _institutionId = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _hospitalName.dispose();
    _hospitalAddress.dispose();
    _hospitalCity.dispose();
    _adminName.dispose();
    _adminPhone.dispose();
    _adminEmail.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    final db = FirebaseFirestore.instance;
    final userDoc = await db.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? {};

    _institutionId = (userData['institutionId'] ?? '').toString();

    Map<String, dynamic> institutionData = {};
    if (_institutionId.isNotEmpty) {
      final institutionDoc =
          await db.collection('institutions').doc(_institutionId).get();
      institutionData = institutionDoc.data() ?? {};
    }

    _hospitalName.text =
        (institutionData['institutionName'] ?? userData['institutionName'] ?? '')
            .toString();
    _hospitalAddress.text = (institutionData['institutionAddress'] ??
            userData['institutionAddress'] ??
            '')
        .toString();
    _hospitalCity.text =
        (institutionData['institutionCity'] ?? userData['institutionCity'] ?? '')
            .toString();
    _adminName.text = (userData['name'] ?? '').toString();
    _adminPhone.text = (userData['phone'] ?? '').toString();
    _adminEmail.text = (userData['email'] ?? '').toString();

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_institutionId.isEmpty) return;

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final db = FirebaseFirestore.instance;

      await db.collection('institutions').doc(_institutionId).set({
        'institutionName': _hospitalName.text.trim(),
        'institutionAddress': _hospitalAddress.text.trim(),
        'institutionCity': _hospitalCity.text.trim(),
        'adminName': _adminName.text.trim(),
        'adminPhone': _adminPhone.text.trim(),
        'adminEmail': _adminEmail.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (uid != null) {
        await db.collection('users').doc(uid).set({
          'name': _adminName.text.trim(),
          'phone': _adminPhone.text.trim(),
          'email': _adminEmail.text.trim(),
          'institutionName': _hospitalName.text.trim(),
          'institutionAddress': _hospitalAddress.text.trim(),
          'institutionCity': _hospitalCity.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hospital profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _copyHospitalId() {
    if (_institutionId.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _institutionId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hospital ID copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: const Text('Hospital Profile'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [PETROL_DARK, PETROL],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hospital Information',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Hospital ID: ',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _institutionId.isEmpty ? '-' : _institutionId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _copyHospitalId,
                            icon: const Icon(Icons.copy, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _InputCard(
                        child: TextFormField(
                          controller: _hospitalName,
                          decoration: const InputDecoration(
                            labelText: 'Hospital Name',
                            border: InputBorder.none,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                      _InputCard(
                        child: TextFormField(
                          controller: _hospitalAddress,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: InputBorder.none,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                          maxLines: 2,
                        ),
                      ),
                      _InputCard(
                        child: TextFormField(
                          controller: _hospitalCity,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            border: InputBorder.none,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                      _InputCard(
                        child: TextFormField(
                          controller: _adminName,
                          decoration: const InputDecoration(
                            labelText: 'Admin Full Name',
                            border: InputBorder.none,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                      _InputCard(
                        child: TextFormField(
                          controller: _adminPhone,
                          decoration: const InputDecoration(
                            labelText: 'Admin Phone',
                            border: InputBorder.none,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                      _InputCard(
                        child: TextFormField(
                          controller: _adminEmail,
                          decoration: const InputDecoration(
                            labelText: 'Admin Email',
                            border: InputBorder.none,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: PETROL_DARK,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.save),
                          label: Text(_saving ? 'Saving...' : 'Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final Widget child;

  const _InputCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PETROL.withOpacity(0.10)),
      ),
      child: child,
    );
  }
}