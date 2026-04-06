import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/doctor.dart';
import '../../utils/constants.dart';
import '../../utils/doctor_specialties.dart';
import '../../utils/localization.dart';

class DoctorSignupScreen extends StatefulWidget {
  const DoctorSignupScreen({super.key});

  @override
  State<DoctorSignupScreen> createState() => _DoctorSignupScreenState();
}

class _DoctorSignupScreenState extends State<DoctorSignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final hospitalIdController = TextEditingController();
  final nameController = TextEditingController();
  final employeeIdController = TextEditingController();
  final workPhoneController = TextEditingController();
  final licenseController = TextEditingController();

  String? selectedMainSpecialty;
  String? selectedSubSpecialty;
  bool loading = false;

  @override
  void dispose() {
    hospitalIdController.dispose();
    nameController.dispose();
    employeeIdController.dispose();
    workPhoneController.dispose();
    licenseController.dispose();
    super.dispose();
  }

  Future<void> registerDoctor() async {
    final tr = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) return;

    if (selectedMainSpecialty == null || selectedSubSpecialty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Choose specialty")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;
      if (user == null) return;

      final hospitalId = hospitalIdController.text.trim().toUpperCase();

      final institutionDoc = await FirebaseFirestore.instance
          .collection('institutions')
          .doc(hospitalId)
          .get();

      if (!institutionDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.translate('institution_not_found'))),
        );
        setState(() => loading = false);
        return;
      }

      final institutionData = institutionDoc.data() ?? {};
      final uid = user.uid;

      final doctor = Doctor(
        uid: uid,
        name: nameController.text.trim(),
        email: user.email ?? '',
        mainSpecialty: selectedMainSpecialty!,
        subSpecialty: selectedSubSpecialty!,
        verificationStatus: 'pending',
        corneaImageUrl: null,
        institutionId: hospitalId,
        institutionName: institutionData['institutionName'] ?? '',
        institutionCode: '',
        departmentId: '',
        departmentName: selectedMainSpecialty!,
        staffRole: 'doctor',
        medicalRole: 'doctor',
        employeeId: employeeIdController.text.trim(),
        licenseNumber: licenseController.text.trim(),
        workPhone: workPhoneController.text.trim(),
        approvalStatus: 'pending',
        availabilityStatus: 'offline',
       
      );

      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(uid)
          .set(doctor.toMap());

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': nameController.text.trim(),
        'email': user.email ?? '',
        'role': 'doctor',
        'phone': workPhoneController.text.trim(),
        'employeeId': employeeIdController.text.trim(),
        'licenseNumber': licenseController.text.trim(),
        'institutionId': hospitalId,
        'institutionName': institutionData['institutionName'] ?? '',
        'departmentName': selectedMainSpecialty!,
        'medicalRole': 'doctor',
        'mainSpecialty': selectedMainSpecialty!,
        'subSpecialty': selectedSubSpecialty!,
        'approvalStatus': 'pending',
        'profileCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('staff_requests').doc(uid).set({
        'uid': uid,
        'name': nameController.text.trim(),
        'email': user.email ?? '',
        'role': 'doctor',
        'medicalRole': 'doctor',
        'departmentName': selectedMainSpecialty!,
        'employeeId': employeeIdController.text.trim(),
        'licenseNumber': licenseController.text.trim(),
        'institutionId': hospitalId,
        'institutionName': institutionData['institutionName'] ?? '',
        'approvalStatus': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.translate('profile_saved'))),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final specialties = DoctorSpecialties.specialties;
    final tr = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.translate('doctor')),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: hospitalIdController,
                decoration: InputDecoration(
                  labelText: tr.translate('hospital_id'),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: tr.translate('full_name'),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: employeeIdController,
                decoration: InputDecoration(
                  labelText: tr.translate('employee_id'),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: workPhoneController,
                decoration: InputDecoration(
                  labelText: tr.translate('work_phone'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: licenseController,
                decoration: InputDecoration(
                  labelText: tr.translate('license_number'),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Main Specialty"),
                value: selectedMainSpecialty,
                items: specialties.keys
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedMainSpecialty = value;
                    selectedSubSpecialty = null;
                  });
                },
              ),
              const SizedBox(height: 10),
              if (selectedMainSpecialty != null)
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Sub Specialty"),
                  value: selectedSubSpecialty,
                  items: specialties[selectedMainSpecialty]!
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedSubSpecialty = value);
                  },
                ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: loading ? null : registerDoctor,
                child: Text(loading ? "Registering..." : "Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}