import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

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
  // الحقول الأساسية
  final _name = TextEditingController();
  DateTime? _selectedBirthDate;
  final _gender = ValueNotifier<String>('Female');
  final _phone = TextEditingController();
  
  // 🔥 الحقول الطبية الجديدة
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _bloodType = ValueNotifier<String>('O+');
  final _allergies = TextEditingController();
  final _chronicDiseases = TextEditingController();
  
  // حقول الطوارئ
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  
  // حقول الربط (اختياري)
  final _doctorId = TextEditingController();
  final _parentId = TextEditingController();

  @override
  void dispose() {
    _name.dispose(); _phone.dispose();
    _weight.dispose(); _height.dispose();
    _allergies.dispose(); _chronicDiseases.dispose();
    _emergencyName.dispose(); _emergencyPhone.dispose();
    _doctorId.dispose(); _parentId.dispose();
    _gender.dispose(); _bloodType.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must login first.')));
      return;
    }

    if (_name.text.isEmpty || _selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter name and birth date.')));
      return;
    }

    final app = Provider.of<AppState>(context, listen: false);

    // إنشاء كائن المريض بجميع البيانات الجديدة
    final p = Patient(
      id: user.uid,
      name: _name.text.trim(),
      email: user.email ?? '',
      birthDate: _selectedBirthDate,
      gender: _gender.value,
      phone: _phone.text.trim(),
      
      // ✅ البيانات الجديدة
      weight: _weight.text.trim(),
      height: _height.text.trim(),
      bloodType: _bloodType.value,
      allergies: _allergies.text.isNotEmpty ? _allergies.text.split(',') : [],
      chronicDiseases: _chronicDiseases.text.isNotEmpty ? _chronicDiseases.text.split(',') : [],
      
      emergencyContactName: _emergencyName.text.trim(),
      emergencyContactPhone: _emergencyPhone.text.trim(),
      
      doctorId: _doctorId.text.trim().isEmpty ? null : _doctorId.text.trim(),
      parentId: _parentId.text.trim().isEmpty ? null : _parentId.text.trim(),
      age: DateTime.now().year - _selectedBirthDate!.year,
    );

    // حفظ البيانات في Firestore
    await app.registerPatient(p);

    if (!mounted) return;

    // الانتقال للصفحة الرئيسية
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => PatientHomeScreen(patient: p)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Profile'), backgroundColor: PETROL_DARK),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            // --- 1. Basic Info ---
            const Text("Basic Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: PETROL)),
            const SizedBox(height: 10),
            TextField(
              controller: _name, 
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))
            ),
            const SizedBox(height: 10),
            ListTile(
              title: Text(_selectedBirthDate == null ? 'Select Birth Date' : DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)),
              trailing: const Icon(Icons.calendar_today, color: PETROL),
              shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _gender,
                    builder: (_, val, __) => DropdownButtonFormField(
                      value: val,
                      items: ['Female', 'Male'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => _gender.value = v.toString(),
                      decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phone, 
                    decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),

            // --- 2. Medical Info ---
            const Text("Medical Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: PETROL)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weight, 
                    decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.monitor_weight)), 
                    keyboardType: TextInputType.number
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _height, 
                    decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.height)), 
                    keyboardType: TextInputType.number
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder(
              valueListenable: _bloodType,
              builder: (_, val, __) => DropdownButtonFormField(
                value: val,
                items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => _bloodType.value = v.toString(),
                decoration: const InputDecoration(labelText: 'Blood Type', border: OutlineInputBorder(), prefixIcon: Icon(Icons.bloodtype)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _chronicDiseases, 
              decoration: const InputDecoration(labelText: 'Chronic Diseases (comma separated)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.sick))
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _allergies, 
              decoration: const InputDecoration(labelText: 'Allergies (comma separated)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.coronavirus))
            ),

            const SizedBox(height: 20),

            // --- 3. Emergency Contact ---
            const Text("Emergency Contact", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
            const SizedBox(height: 10),
            TextField(
              controller: _emergencyName, 
              decoration: const InputDecoration(labelText: 'Contact Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline))
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emergencyPhone, 
              decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_in_talk)), 
              keyboardType: TextInputType.phone
            ),

            const SizedBox(height: 30),
            
            // --- Save Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PETROL, 
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text('Save & Continue', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}