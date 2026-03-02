import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/constants.dart';
import '../../providers/app_state.dart'; 
import '../../utils/localization.dart';
import '../auth/login_screen.dart';
import 'edit_patient_profile_screen.dart';

class PatientSettingsScreen extends StatefulWidget {
  final String? patientId; 
  final VoidCallback? onLogout;

  const PatientSettingsScreen({super.key, this.patientId, this.onLogout});

  @override
  State<PatientSettingsScreen> createState() => _PatientSettingsScreenState();
}

class _PatientSettingsScreenState extends State<PatientSettingsScreen> {
  final _doctorIdCtrl = TextEditingController();
  final _parentIdCtrl = TextEditingController();
  bool _saving = false;

  String get _uid => widget.patientId ?? FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  @override
  void dispose() {
    _doctorIdCtrl.dispose();
    _parentIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLinks() async {
    if (_uid.isEmpty) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(_uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _doctorIdCtrl.text = data['doctorId'] ?? '';
      _parentIdCtrl.text = data['parentId'] ?? '';
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveLinks() async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance.collection('users').doc(_uid).update({
      'doctorId': _doctorIdCtrl.text.trim(),
      'parentId': _parentIdCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Links Saved Successfully')));
    }
  }

  Future<void> _handleLogout() async {
    try {
      await Provider.of<AppState>(context, listen: false).disconnectDevice();
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()), 
          (route) => false
        );
      }
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[700], size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true, fillColor: Colors.grey.shade50,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);
    final app = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(lang.translate('settings')), backgroundColor: PETROL_DARK),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. زر تعديل البيانات الشخصية
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditPatientProfileScreen()));
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                  border: Border.all(color: Colors.grey.shade200)
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Update Personal Info", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. Links (Doctor & Parent)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF0F4F4), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Connected Accounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(controller: _doctorIdCtrl, decoration: _inputDecor('Doctor ID', Icons.medical_services).copyWith(fillColor: Colors.white)),
                  const SizedBox(height: 12),
                  TextFormField(controller: _parentIdCtrl, decoration: _inputDecor('Parent ID', Icons.family_restroom).copyWith(fillColor: Colors.white)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveLinks,
                      style: ElevatedButton.styleFrom(backgroundColor: PETROL, foregroundColor: Colors.white),
                      child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Save Links"),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Device Connection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF0F4F4), borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(app.isDeviceConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, 
                         color: app.isDeviceConnected ? PETROL : Colors.grey),
                    title: Text(app.isDeviceConnected ? "Connected" : "Disconnected"),
                    subtitle: Text(app.deviceStatus),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: (app.isDeviceConnected || app.deviceStatus == "Scanning...") ? null : () => app.connectDevice(_uid),
                          style: ElevatedButton.styleFrom(backgroundColor: PETROL, foregroundColor: Colors.white),
                          icon: const Icon(Icons.bluetooth),
                          label: const Text('Connect'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: app.isDeviceConnected ? () => app.disconnectDevice() : null,
                          child: const Text('Disconnect'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Language & Logout
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Colors.orangeAccent, child: Icon(Icons.language, color: Colors.white)),
              title: Text(lang.translate('change_lang')),
              trailing: Switch(activeColor: PETROL, value: app.currentLocale.languageCode == 'ar', onChanged: (val) => app.changeLanguage(val ? 'ar' : 'en')),
            ),
            
            const Divider(),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleLogout, 
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                icon: const Icon(Icons.logout),
                label: Text(lang.translate('logout')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}