import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../auth/welcome_screen.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<Map<String, dynamic>> _fetchParentData() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    return snap.data() ?? {};
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 250));
  }

  void _openEditParentProfileSheet(Map<String, dynamic> currentData) {
    final nameCtrl = TextEditingController(
      text: (currentData['name'] ?? '').toString(),
    );
    final phoneCtrl = TextEditingController(
      text: (currentData['phone'] ?? '').toString(),
    );
    final relationCtrl = TextEditingController(
      text: (currentData['relation'] ?? '').toString(),
    );
    final addressCtrl = TextEditingController(
      text: (currentData['address'] ?? '').toString(),
    );
    final emergencyCtrl = TextEditingController(
      text: (currentData['emergencyPhone'] ?? '').toString(),
    );
    final nationalIdCtrl = TextEditingController(
      text: (currentData['nationalId'] ?? '').toString(),
    );
    final genderCtrl = TextEditingController(
      text: (currentData['gender'] ?? '').toString(),
    );
    final dobCtrl = TextEditingController(
      text: (currentData['dateOfBirth'] ?? '').toString(),
    );

    bool notificationsEnabled = currentData['notificationsEnabled'] == true;
    bool criticalAlertsOnly = currentData['criticalAlertsOnly'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Edit Parent Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _field('Name', nameCtrl, icon: Icons.person),
                    const SizedBox(height: 10),
                    _field(
                      'Phone',
                      phoneCtrl,
                      icon: Icons.phone,
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      'Relation',
                      relationCtrl,
                      icon: Icons.family_restroom,
                    ),
                    const SizedBox(height: 10),
                    _field('Address', addressCtrl, icon: Icons.location_on),
                    const SizedBox(height: 10),
                    _field(
                      'Emergency Phone',
                      emergencyCtrl,
                      icon: Icons.emergency,
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    _field(
                      'National ID',
                      nationalIdCtrl,
                      icon: Icons.badge,
                      keyboard: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    _field('Gender', genderCtrl, icon: Icons.wc),
                    const SizedBox(height: 10),
                    _field(
                      'Date of Birth',
                      dobCtrl,
                      icon: Icons.calendar_today,
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      value: notificationsEnabled,
                      onChanged: (v) {
                        setModalState(() => notificationsEnabled = v);
                      },
                      title: const Text('Enable Notifications'),
                      activeThumbColor: PETROL_DARK,
                    ),
                    SwitchListTile(
                      value: criticalAlertsOnly,
                      onChanged: (v) {
                        setModalState(() => criticalAlertsOnly = v);
                      },
                      title: const Text('Critical Alerts Only'),
                      activeThumbColor: PETROL_DARK,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PETROL_DARK,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_uid)
                                .set({
                                  'uid': _uid,
                                  'role': 'parent',
                                  'name': nameCtrl.text.trim(),
                                  'phone': phoneCtrl.text.trim(),
                                  'relation': relationCtrl.text.trim(),
                                  'address': addressCtrl.text.trim(),
                                  'emergencyPhone': emergencyCtrl.text.trim(),
                                  'nationalId': nationalIdCtrl.text.trim(),
                                  'gender': genderCtrl.text.trim(),
                                  'dateOfBirth': dobCtrl.text.trim(),
                                  'notificationsEnabled': notificationsEnabled,
                                  'criticalAlertsOnly': criticalAlertsOnly,
                                  'profileCompleted': true,
                                  'updatedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));

                            if (!mounted) return;

                            Navigator.pop(sheetContext);
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Parent profile updated ✅'),
                              ),
                            );
                            setState(() {});
                          } catch (e) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          'Save Changes',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _infoTile(String title, String value, IconData icon) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: PETROL.withValues(alpha: 0.12),
            child: Icon(icon, size: 18, color: PETROL_DARK),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boolTile(String title, bool value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: PETROL.withValues(alpha: 0.12),
            child: Icon(icon, size: 18, color: PETROL_DARK),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value ? 'Enabled' : 'Disabled',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: value ? Colors.green : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: PETROL_DARK,
        title: const Text(
          'Parent Settings',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchParentData(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data ?? {};
          final name = (data['name'] ?? '').toString();
          final phone = (data['phone'] ?? '').toString();
          final relation = (data['relation'] ?? '').toString();
          final address = (data['address'] ?? '').toString();
          final emergencyPhone = (data['emergencyPhone'] ?? '').toString();
          final nationalId = (data['nationalId'] ?? '').toString();
          final gender = (data['gender'] ?? '').toString();
          final dateOfBirth = (data['dateOfBirth'] ?? '').toString();
          final notificationsEnabled = data['notificationsEnabled'] == true;
          final criticalAlertsOnly = data['criticalAlertsOnly'] == true;
          final linkedPatients = List<String>.from(
            data['linkedPatients'] ?? const [],
          );

          return RefreshIndicator(
            color: PETROL_DARK,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [PETROL_DARK, PETROL],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.family_restroom_rounded,
                          color: PETROL_DARK,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name.isEmpty ? 'Parent Profile' : name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        relation.isEmpty ? 'Family Account' : relation,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Profile Information',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: PETROL_DARK,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _infoTile('Name', name, Icons.person),
                      _infoTile('Phone', phone, Icons.phone),
                      _infoTile(
                        'Relation',
                        relation,
                        Icons.family_restroom_rounded,
                      ),
                      _infoTile('Address', address, Icons.location_on),
                      _infoTile(
                        'Emergency Phone',
                        emergencyPhone,
                        Icons.emergency_rounded,
                      ),
                      _infoTile('National ID', nationalId, Icons.badge_rounded),
                      _infoTile('Gender', gender, Icons.wc),
                      _infoTile(
                        'Date of Birth',
                        dateOfBirth,
                        Icons.calendar_today_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferences',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: PETROL_DARK,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _boolTile(
                        'Notifications',
                        notificationsEnabled,
                        Icons.notifications_active_rounded,
                      ),
                      _boolTile(
                        'Critical Alerts Only',
                        criticalAlertsOnly,
                        Icons.warning_amber_rounded,
                      ),
                      _infoTile(
                        'Linked Patients',
                        '${linkedPatients.length}',
                        Icons.people_alt_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PETROL_DARK,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _openEditParentProfileSheet(data),
                    icon: const Icon(Icons.edit, color: Colors.white),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
