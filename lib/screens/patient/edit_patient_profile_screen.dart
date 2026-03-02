import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/constants.dart';

class EditPatientProfileScreen extends StatefulWidget {
  const EditPatientProfileScreen({super.key});

  @override
  State<EditPatientProfileScreen> createState() => _EditPatientProfileScreenState();
}

class _EditPatientProfileScreenState extends State<EditPatientProfileScreen> {
  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  final _emergencyNameCtrl = TextEditingController(); // اسم الشخص للطوارئ
  
  // Medical Controllers
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _chronicCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  String _bloodType = 'O+';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose(); 
    _emergencyPhoneCtrl.dispose(); _emergencyNameCtrl.dispose();
    _weightCtrl.dispose(); _heightCtrl.dispose(); 
    _chronicCtrl.dispose(); _allergiesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _nameCtrl.text = data['name'] ?? '';
          _phoneCtrl.text = data['phone'] ?? '';
          _emergencyPhoneCtrl.text = data['emergencyContactPhone'] ?? '';
          _emergencyNameCtrl.text = data['emergencyContactName'] ?? '';
          
          _weightCtrl.text = data['weight'] ?? '';
          _heightCtrl.text = data['height'] ?? '';
          _bloodType = data['bloodType'] ?? 'O+';
          
          List<dynamic> chronic = data['chronicDiseases'] ?? [];
          _chronicCtrl.text = chronic.join(', ');

          List<dynamic> allergies = data['allergies'] ?? [];
          _allergiesCtrl.text = allergies.join(', ');
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'emergencyContactName': _emergencyNameCtrl.text.trim(),
        'emergencyContactPhone': _emergencyPhoneCtrl.text.trim(),
        'weight': _weightCtrl.text.trim(),
        'height': _heightCtrl.text.trim(),
        'bloodType': _bloodType,
        'chronicDiseases': _chronicCtrl.text.isNotEmpty ? _chronicCtrl.text.split(',').map((e)=>e.trim()).toList() : [],
        'allergies': _allergiesCtrl.text.isNotEmpty ? _allergiesCtrl.text.split(',').map((e)=>e.trim()).toList() : [],
      });
      
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated Successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context); // الرجوع لصفحة الإعدادات بعد الحفظ
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Information"),
        backgroundColor: PETROL_DARK,
        actions: [
          IconButton(onPressed: _saveProfile, icon: const Icon(Icons.check))
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSectionHeader("Personal Info"),
                _buildTextField(_nameCtrl, "Full Name", Icons.person),
                const SizedBox(height: 10),
                _buildTextField(_phoneCtrl, "Phone Number", Icons.phone),
                
                const SizedBox(height: 20),
                _buildSectionHeader("Emergency Contact"),
                _buildTextField(_emergencyNameCtrl, "Contact Name", Icons.person_outline),
                const SizedBox(height: 10),
                _buildTextField(_emergencyPhoneCtrl, "Contact Phone", Icons.phone_in_talk, isRed: true),

                const SizedBox(height: 20),
                _buildSectionHeader("Medical Profile"),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_weightCtrl, "Weight (kg)", Icons.monitor_weight)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_heightCtrl, "Height (cm)", Icons.height)),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _bloodType,
                  items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _bloodType = v!),
                  decoration: const InputDecoration(labelText: "Blood Type", prefixIcon: Icon(Icons.bloodtype, color: Colors.red), border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                ),
                const SizedBox(height: 10),
                _buildTextField(_chronicCtrl, "Chronic Diseases", Icons.sick),
                const SizedBox(height: 10),
                _buildTextField(_allergiesCtrl, "Allergies", Icons.coronavirus),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PETROL, 
                      padding: const EdgeInsets.symmetric(vertical: 15)
                    ),
                    child: const Text("Save Information", style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: PETROL_DARK))),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, {bool isRed = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: label.contains("Phone") || label.contains("Weight") || label.contains("Height") ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: isRed ? Colors.red : Colors.grey),
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }
}