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

  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _aboutController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String _institutionId = '';
  String _ownerUid = '';

  @override
  void initState() {
    super.initState();
    _loadHospitalProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadHospitalProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _loading = false);
        return;
      }

      _ownerUid = uid;

      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};

      final institutionId = (userData['institutionId'] ?? '').toString();
      _institutionId = institutionId;

      Map<String, dynamic> institutionData = {};
      if (institutionId.isNotEmpty) {
        final institutionDoc =
            await db.collection('institutions').doc(institutionId).get();
        institutionData = institutionDoc.data() ?? {};
      }

      _nameController.text = (institutionData['institutionName'] ??
              userData['institutionName'] ??
              '')
          .toString();

      _cityController.text = (institutionData['institutionCity'] ??
              userData['institutionCity'] ??
              '')
          .toString();

      _addressController.text =
          (institutionData['address'] ?? userData['address'] ?? '').toString();

      _phoneController.text =
          (institutionData['phone'] ?? userData['phone'] ?? '').toString();

      _emailController.text = (institutionData['email'] ??
              userData['email'] ??
              FirebaseAuth.instance.currentUser?.email ??
              '')
          .toString();

      _aboutController.text =
          (institutionData['about'] ?? userData['about'] ?? '').toString();
    } catch (e) {
      debugPrint('load hospital profile error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _copyInstitutionId() async {
    if (_institutionId.trim().isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _institutionId));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hospital ID copied'),
      ),
    );
  }

  Future<void> _saveHospitalProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_institutionId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Hospital ID found for this account'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final db = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();

      final institutionPayload = {
        'institutionId': _institutionId,
        'institutionName': _nameController.text.trim(),
        'institutionCity': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'about': _aboutController.text.trim(),
        'ownerUid': _ownerUid,
        'updatedAt': now,
      };

      await db
          .collection('institutions')
          .doc(_institutionId)
          .set(institutionPayload, SetOptions(merge: true));

      await db.collection('users').doc(_ownerUid).set({
        'institutionId': _institutionId,
        'institutionName': _nameController.text.trim(),
        'institutionCity': _cityController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'about': _aboutController.text.trim(),
        'role': 'hospital',
        'updatedAt': now,
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hospital profile updated successfully'),
        ),
      );
    } catch (e) {
      debugPrint('save hospital profile error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        backgroundColor: LIGHT_BG,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Hospital Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
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
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 18,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white24,
                                child: Icon(
                                  Icons.local_hospital_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Main Hospital Account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Hospital ID',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _institutionId.isEmpty
                                        ? 'No ID found'
                                        : _institutionId,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      _institutionId.isEmpty ? null : _copyInstitutionId,
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    color: Colors.white,
                                  ),
                                  tooltip: 'Copy Hospital ID',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Use this ID for doctor, nurse, and staff registration.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        label: 'Hospital Name',
                        icon: Icons.business_rounded,
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: _inputDecoration(
                        label: 'City',
                        icon: Icons.location_city_rounded,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: _inputDecoration(
                        label: 'Address',
                        icon: Icons.place_rounded,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: _inputDecoration(
                        label: 'Phone',
                        icon: Icons.phone_rounded,
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: _inputDecoration(
                        label: 'Hospital Email',
                        icon: Icons.email_rounded,
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _aboutController,
                      decoration: _inputDecoration(
                        label: 'About Hospital',
                        icon: Icons.info_outline_rounded,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveHospitalProfile,
                        icon: _saving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_saving ? 'Saving...' : 'Save Changes'),
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