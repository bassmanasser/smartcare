import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/patient.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../widgets/language_picker.dart';
import 'patient_home_screen.dart';

class PatientSignUpScreen extends StatefulWidget {
  const PatientSignUpScreen({super.key});

  @override
  State<PatientSignUpScreen> createState() => _PatientSignUpScreenState();
}

class _PatientSignUpScreenState extends State<PatientSignUpScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _allergies = TextEditingController();
  final _chronicDiseases = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _institutionCode = TextEditingController();

  DateTime? _selectedBirthDate;
  final _gender = ValueNotifier('Female');
  final _bloodType = ValueNotifier('O+');
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _weight.dispose();
    _height.dispose();
    _allergies.dispose();
    _chronicDiseases.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    _institutionCode.dispose();
    _gender.dispose();
    _bloodType.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedBirthDate = picked);
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must login first.')),
      );
      return;
    }

    if (_name.text.isEmpty || _selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name and birth date.')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final app = Provider.of<AppState>(context, listen: false);

      final p = Patient(
        id: user.uid,
        name: _name.text.trim(),
        email: user.email ?? '',
        birthDate: _selectedBirthDate,
        gender: _gender.value,
        phone: _phone.text.trim(),
        weight: _weight.text.trim(),
        height: _height.text.trim(),
        bloodType: _bloodType.value,
        allergies: _allergies.text.isNotEmpty ? _allergies.text.split(',') : [],
        chronicDiseases:
            _chronicDiseases.text.isNotEmpty ? _chronicDiseases.text.split(',') : [],
        emergencyContactName: _emergencyName.text.trim(),
        emergencyContactPhone: _emergencyPhone.text.trim(),
        doctorId: null,
        parentId: null,
        age: DateTime.now().year - _selectedBirthDate!.year,
      );

      await app.registerPatient(p, institutionCode: _institutionCode.text.trim());

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => PatientHomeScreen(patient: p)),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('patient_intake')),
        backgroundColor: petrolDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: lang.translate('language'),
            onPressed: () => showLanguagePicker(context),
            icon: const Icon(Icons.language_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              lang.translate('profile'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: petrol),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: lang.translate('full_name'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            ListTile(
              title: Text(
                _selectedBirthDate == null
                    ? lang.translate('date')
                    : DateFormat('yyyy-MM-dd').format(_selectedBirthDate!),
              ),
              trailing: const Icon(Icons.calendar_today, color: petrol),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(6),
              ),
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _gender,
                    builder: (_, val, _) => DropdownButtonFormField<String>(
                      initialValue: val,
                      items: const [
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                      ],
                      onChanged: (v) => _gender.value = v ?? 'Female',
                      decoration: InputDecoration(
                        labelText: lang.translate('gender'),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phone,
                    decoration: InputDecoration(
                      labelText: lang.translate('phone'),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              lang.translate('institution'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: petrol),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _institutionCode,
              decoration: InputDecoration(
                labelText: '${lang.translate('hospital_id')} (${lang.translate('optional')})',
                hintText: 'Example: smartcare_hospital',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_hospital),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              lang.translate('medical_profile'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: petrol),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weight,
                    decoration: InputDecoration(
                      labelText: lang.translate('weight'),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.monitor_weight),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _height,
                    decoration: InputDecoration(
                      labelText: lang.translate('height'),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.height),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<String>(
              valueListenable: _bloodType,
              builder: (_, val, _) => DropdownButtonFormField<String>(
                initialValue: val,
                items: const [
                  DropdownMenuItem(value: 'A+', child: Text('A+')),
                  DropdownMenuItem(value: 'A-', child: Text('A-')),
                  DropdownMenuItem(value: 'B+', child: Text('B+')),
                  DropdownMenuItem(value: 'B-', child: Text('B-')),
                  DropdownMenuItem(value: 'O+', child: Text('O+')),
                  DropdownMenuItem(value: 'O-', child: Text('O-')),
                  DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                  DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                ],
                onChanged: (v) => _bloodType.value = v ?? 'O+',
                decoration: InputDecoration(
                  labelText: lang.translate('blood_type'),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.bloodtype),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _chronicDiseases,
              decoration: InputDecoration(
                labelText: lang.translate('chronic_diseases'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _allergies,
              decoration: InputDecoration(
                labelText: lang.translate('allergies'),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              lang.translate('emergency_contact'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emergencyName,
              decoration: InputDecoration(
                labelText: lang.translate('contact_name'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emergencyPhone,
              decoration: InputDecoration(
                labelText: lang.translate('contact_phone'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_in_talk),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: petrol,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        lang.translate('save_continue'),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
