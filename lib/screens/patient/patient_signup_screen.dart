import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../models/patient.dart';
import '../../utils/constants.dart';
import 'patient_home_screen.dart';

class PatientSignUpScreen extends StatefulWidget {
  const PatientSignUpScreen({super.key});

  @override
  State<PatientSignUpScreen> createState() => _PatientSignUpScreenState();
}

class _PatientSignUpScreenState extends State<PatientSignUpScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _gender = ValueNotifier<String>('Female');
  final _doctorId = TextEditingController();
  final _parentId = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _doctorId.dispose();
    _parentId.dispose();
    _gender.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must login first.')),
      );
      return;
    }

    final app = Provider.of<AppState>(context, listen: false);
    final ageNum = int.tryParse(_age.text.trim()) ?? 0;

    final p = Patient(
      id: user.uid,
      name: _name.text.trim().isEmpty ? 'Patient' : _name.text.trim(),
      age: ageNum,
      gender: _gender.value,
      doctorId: _doctorId.text.trim().isEmpty
          ? null
          : _doctorId.text.trim(),
      parentId: _parentId.text.trim().isEmpty
          ? null
          : _parentId.text.trim(),
      email: user.email,
    );

    await app.registerPatient(p);

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => PatientHomeScreen(patient: p),
      ),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        backgroundColor: PETROL_DARK,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String>(
              valueListenable: _gender,
              builder: (context, value, _) {
                return DropdownButtonFormField<String>(
                  value: value,
                  items: const [
                    DropdownMenuItem(
                      value: 'Female',
                      child: Text('Female'),
                    ),
                    DropdownMenuItem(
                      value: 'Male',
                      child: Text('Male'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('Other'),
                    ),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    if (v != null) _gender.value = v;
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _doctorId,
              decoration: const InputDecoration(
                labelText: 'Doctor ID (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _parentId,
              decoration: const InputDecoration(
                labelText: 'Parent ID (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PETROL,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Save & Continue',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
