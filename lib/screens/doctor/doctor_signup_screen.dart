import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/doctor.dart';
import '../../utils/constants.dart';

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Step 1
  final _fullName = TextEditingController();
  final _workEmail = TextEditingController();
  final _password = TextEditingController();

  // Step 2
  final _institutionCode = TextEditingController();
  final _institutionName = TextEditingController();
  final _department = TextEditingController();
  final _employeeId = TextEditingController();
  final _workPhone = TextEditingController();

  // Step 3
  final _licenseNumber = TextEditingController();
  final _specialty = TextEditingController();

  String _staffRole = 'doctor';
  String _medicalRole = 'Attending Physician';
  int _step = 0;
  bool _loading = false;
  File? _proofFile;

  @override
  void dispose() {
    _fullName.dispose();
    _workEmail.dispose();
    _password.dispose();
    _institutionCode.dispose();
    _institutionName.dispose();
    _department.dispose();
    _employeeId.dispose();
    _workPhone.dispose();
    _licenseNumber.dispose();
    _specialty.dispose();
    super.dispose();
  }

  Future<void> _pickProof() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _proofFile = File(picked.path));
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final auth = FirebaseAuth.instance;
      final current = auth.currentUser;

      User user;
      if (current == null) {
        final cred = await auth.createUserWithEmailAndPassword(
          email: _workEmail.text.trim(),
          password: _password.text.trim(),
        );
        user = cred.user!;
      } else {
        user = current;
      }

      final uid = user.uid;
      final institutionId = _institutionCode.text.trim().toLowerCase();

      final staff = Doctor(
        uid: uid,
        name: _fullName.text.trim(),
        email: _workEmail.text.trim(),
        institutionId: institutionId,
        institutionName: _institutionName.text.trim(),
        institutionCode: _institutionCode.text.trim(),
        departmentId: _department.text.trim().toLowerCase().replaceAll(' ', '_'),
        departmentName: _department.text.trim(),
        staffRole: _staffRole,
        medicalRole: _medicalRole,
        employeeId: _employeeId.text.trim(),
        licenseNumber: _licenseNumber.text.trim(),
        workPhone: _workPhone.text.trim(),
        approvalStatus: 'pending',
        availabilityStatus: 'available',
        uploadProofUrl: _proofFile?.path,
        mainSpecialty: _specialty.text.trim(),
        subSpecialty: '',
      );

      final db = FirebaseFirestore.instance;

      await db.collection('institutions').doc(institutionId).set({
        'id': institutionId,
        'name': _institutionName.text.trim(),
        'code': _institutionCode.text.trim(),
        'type': 'Hospital',
        'address': '',
        'phone': '',
        'email': _workEmail.text.trim(),
        'status': 'active',
        'departments': FieldValue.arrayUnion([_department.text.trim()]),
      }, SetOptions(merge: true));

      await db.collection('departments').doc('${institutionId}_${staff.departmentId}').set({
        'id': staff.departmentId,
        'institutionId': institutionId,
        'name': _department.text.trim(),
      }, SetOptions(merge: true));

      await db.collection('users').doc(uid).set(staff.toJson(), SetOptions(merge: true));

      await db.collection('staff_requests').doc(uid).set({
        ...staff.toJson(),
        'uid': uid,
        'approvalStatus': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Institutional access request submitted successfully.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Step _buildStep1() {
    return Step(
      title: const Text('Identity'),
      isActive: _step >= 0,
      content: Column(
        children: [
          TextFormField(
            controller: _fullName,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _workEmail,
            decoration: const InputDecoration(
              labelText: 'Institution Email',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
          ),
        ],
      ),
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text('Institution Info'),
      isActive: _step >= 1,
      content: Column(
        children: [
          TextFormField(
            controller: _institutionName,
            decoration: const InputDecoration(
              labelText: 'Hospital / Institution Name',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _institutionCode,
            decoration: const InputDecoration(
              labelText: 'Institution Code',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _department,
            decoration: const InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _staffRole,
            decoration: const InputDecoration(
              labelText: 'System Role',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
              DropdownMenuItem(value: 'nurse', child: Text('Nurse')),
              DropdownMenuItem(value: 'triage_staff', child: Text('Triage Staff')),
              DropdownMenuItem(value: 'hospital_admin', child: Text('Hospital Admin')),
            ],
            onChanged: (v) => setState(() => _staffRole = v ?? 'doctor'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _employeeId,
            decoration: const InputDecoration(
              labelText: 'Employee ID',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _workPhone,
            decoration: const InputDecoration(
              labelText: 'Work Phone',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildStep3() {
    return Step(
      title: const Text('Verification'),
      isActive: _step >= 2,
      content: Column(
        children: [
          TextFormField(
            controller: _specialty,
            decoration: const InputDecoration(
              labelText: 'Specialty / Focus Area',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _licenseNumber,
            decoration: const InputDecoration(
              labelText: 'License Number',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _medicalRole,
            decoration: const InputDecoration(
              labelText: 'Medical Role',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Attending Physician', child: Text('Attending Physician')),
              DropdownMenuItem(value: 'Resident Doctor', child: Text('Resident Doctor')),
              DropdownMenuItem(value: 'Consultant', child: Text('Consultant')),
              DropdownMenuItem(value: 'Nurse', child: Text('Nurse')),
              DropdownMenuItem(value: 'Triage Officer', child: Text('Triage Officer')),
              DropdownMenuItem(value: 'Hospital Admin', child: Text('Hospital Admin')),
            ],
            onChanged: (v) => setState(() => _medicalRole = v ?? 'Attending Physician'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pickProof,
              icon: const Icon(Icons.upload_file),
              label: Text(_proofFile == null ? 'Upload Proof' : 'Proof Selected'),
            ),
          ),
          if (_proofFile != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: LIGHT_BG,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_proofFile!.path.split('/').last),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: const Text('Medical Staff Registration'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _step,
          type: StepperType.vertical,
          controlsBuilder: (context, details) {
            final isLast = _step == 2;
            return Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            if (isLast) {
                              _submitRequest();
                            } else {
                              setState(() => _step += 1);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PETROL_DARK,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _loading
                          ? 'Please wait...'
                          : isLast
                              ? 'Request Institutional Access'
                              : 'Continue',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => setState(() => _step -= 1),
                      child: const Text('Back'),
                    ),
                  ),
              ],
            );
          },
          steps: [
            _buildStep1(),
            _buildStep2(),
            _buildStep3(),
          ],
        ),
      ),
    );
  }
}