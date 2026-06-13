import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/constants.dart';
import '../../utils/localization.dart';
import '../../widgets/language_picker.dart';

class ParentSignUpScreen extends StatefulWidget {
  const ParentSignUpScreen({super.key});

  @override
  State<ParentSignUpScreen> createState() => _ParentSignUpScreenState();
}

class _ParentSignUpScreenState extends State<ParentSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _passwordController = TextEditingController();
  final _address = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _nationalId = TextEditingController();
  final _gender = ValueNotifier<String>('Female');
  final _relation = ValueNotifier<String>('Father');
  final _dateOfBirth = TextEditingController();

  bool _notificationsEnabled = true;
  bool _criticalAlertsOnly = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _passwordController.dispose();
    _address.dispose();
    _emergencyPhone.dispose();
    _nationalId.dispose();
    _dateOfBirth.dispose();
    _gender.dispose();
    _relation.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 30, 1, 1);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: now,
    );

    if (picked != null) {
      _dateOfBirth.text =
          "${picked.year.toString().padLeft(4, '0')}-"
          "${picked.month.toString().padLeft(2, '0')}-"
          "${picked.day.toString().padLeft(2, '0')}";
      setState(() {});
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final emailAsPhone = "${_phone.text.trim()}@parent.local";

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailAsPhone,
        password: _passwordController.text.trim(),
      );

      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'role': 'parent',
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'address': _address.text.trim(),
        'relation': _relation.value,
        'emergencyPhone': _emergencyPhone.text.trim(),
        'nationalId': _nationalId.text.trim(),
        'gender': _gender.value,
        'dateOfBirth': _dateOfBirth.text.trim(),
        'notificationsEnabled': _notificationsEnabled,
        'criticalAlertsOnly': _criticalAlertsOnly,
        'linkedPatients': [],
        'profileCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Signup failed: $e")),
      );
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: petrolDark,
        title: Text(
          lang.translate('parent'),
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: lang.translate('language'),
            onPressed: () => showLanguagePicker(context),
            icon: const Icon(Icons.language_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: _decoration(lang.translate('full_name'), Icons.person),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: _decoration(lang.translate('phone'), Icons.phone),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _decoration(lang.translate('password'), Icons.lock),
                validator: (v) =>
                    (v == null || v.length < 6) ? "Min 6 chars" : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _address,
                decoration: _decoration(lang.translate('address'), Icons.location_on),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _emergencyPhone,
                keyboardType: TextInputType.phone,
                decoration:
                    _decoration(lang.translate('emergency_phone'), Icons.emergency_rounded),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _nationalId,
                keyboardType: TextInputType.number,
                decoration: _decoration(lang.translate('national_id'), Icons.badge_rounded),
              ),
              const SizedBox(height: 14),

              ValueListenableBuilder<String>(
                valueListenable: _relation,
                builder: (_, v, _) {
                  return DropdownButtonFormField<String>(
                    initialValue: v,
                    decoration:
                        _decoration(lang.translate('relation'), Icons.family_restroom_rounded),
                    items: const [
                      DropdownMenuItem(value: "Father", child: Text("Father")),
                      DropdownMenuItem(value: "Mother", child: Text("Mother")),
                      DropdownMenuItem(
                          value: "Guardian", child: Text("Guardian")),
                      DropdownMenuItem(value: "Sister", child: Text("Sister")),
                      DropdownMenuItem(value: "Brother", child: Text("Brother")),
                    ],
                    onChanged: (x) => _relation.value = x ?? "Father",
                  );
                },
              ),
              const SizedBox(height: 14),

              ValueListenableBuilder<String>(
                valueListenable: _gender,
                builder: (_, v, _) {
                  return DropdownButtonFormField<String>(
                    initialValue: v,
                    decoration: _decoration(lang.translate('gender'), Icons.wc),
                    items: const [
                      DropdownMenuItem(value: "Female", child: Text("Female")),
                      DropdownMenuItem(value: "Male", child: Text("Male")),
                    ],
                    onChanged: (x) => _gender.value = x ?? "Female",
                  );
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _dateOfBirth,
                readOnly: true,
                onTap: _pickDateOfBirth,
                decoration: _decoration(
                  lang.translate('date_of_birth'),
                  Icons.calendar_today_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: _pickDateOfBirth,
                    icon: const Icon(Icons.date_range_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  value: _notificationsEnabled,
                  onChanged: (v) {
                    setState(() => _notificationsEnabled = v);
                  },
                  title: Text(lang.translate('enable_notifications')),
                  activeThumbColor: petrolDark,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  value: _criticalAlertsOnly,
                  onChanged: (v) {
                    setState(() => _criticalAlertsOnly = v);
                  },
                  title: Text(lang.translate('critical_alerts_only')),
                  activeThumbColor: petrolDark,
                ),
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: petrolDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoading ? null : _signUp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          lang.translate('save'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
