import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../auth/welcome_screen.dart';
import '../doctor/patient_detail_for_doctor_screen.dart';
import 'parent_settings_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key, required parent});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<Map<String, dynamic>> _fetchParentData() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    return snap.data() ?? {};
  }

  dynamic _readAny(dynamic item, List<String> fields) {
    for (final field in fields) {
      try {
        final value = _readField(item, field);
        if (value != null) return value;
      } catch (_) {}
    }
    return null;
  }

  dynamic _readField(dynamic item, String field) {
    switch (field) {
      case 'id':
        return (item as dynamic).id;
      case 'name':
        return (item as dynamic).name;
      case 'doctorId':
        return (item as dynamic).doctorId;
      case 'parentId':
        return (item as dynamic).parentId;
      case 'guardianId':
        return (item as dynamic).guardianId;
      case 'caregiverId':
        return (item as dynamic).caregiverId;
      case 'age':
        return (item as dynamic).age;
      case 'condition':
        return (item as dynamic).condition;
      case 'heartRate':
        return (item as dynamic).heartRate;
      case 'spo2':
        return (item as dynamic).spo2;
      case 'temperature':
        return (item as dynamic).temperature;
      case 'lastReadingTime':
        return (item as dynamic).lastReadingTime;
      default:
        return null;
    }
  }

  List<dynamic> _myChildren(Map<dynamic, dynamic> patientsMap, String uid) {
    return patientsMap.values.where((p) {
      final parentId = _readAny(p, ['parentId', 'guardianId', 'caregiverId']);
      return parentId != null && parentId.toString() == uid;
    }).toList();
  }

  String _childName(dynamic child) {
    final name = _readAny(child, ['name']);
    return (name == null || name.toString().trim().isEmpty)
        ? 'Unknown Child'
        : name.toString();
  }

  String _childSubtitle(dynamic child) {
    final age = _readAny(child, ['age']);
    final condition = _readAny(child, ['condition']);

    final parts = <String>[];
    if (age != null) parts.add('Age: $age');
    if (condition != null && condition.toString().trim().isNotEmpty) {
      parts.add(condition.toString());
    }

    return parts.isEmpty ? 'Follow-up profile' : parts.join(' • ');
  }

  String _reading(dynamic value, String unit) {
    if (value == null || value.toString().trim().isEmpty) return '--';
    return '${value.toString()}$unit';
  }

  int _criticalCount(List<dynamic> children) {
    int count = 0;
    for (final c in children) {
      final hr = _readAny(c, ['heartRate']);
      final spo2 = _readAny(c, ['spo2']);

      final hrNum = num.tryParse('$hr');
      final spo2Num = num.tryParse('$spo2');

      final badHr = hrNum != null && (hrNum < 55 || hrNum > 120);
      final badSpo2 = spo2Num != null && spo2Num < 92;

      if (badHr || badSpo2) count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppState>(context);
    final patientsMap = app.patients ?? {};
    final children = _myChildren(patientsMap, _uid);
    final criticalCount = _criticalCount(children);

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchParentData(),
      builder: (context, parentSnap) {
        final parentData = parentSnap.data ?? {};
        final parentName = (parentData['name'] ?? '').toString().trim();
        final relation = (parentData['relation'] ?? '').toString().trim();
        final notificationsEnabled = parentData['notificationsEnabled'] == true;
        final criticalAlertsOnly = parentData['criticalAlertsOnly'] == true;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FB),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: PETROL_DARK,
            title: Text(
              parentName.isEmpty ? 'Parent Dashboard' : parentName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParentSettingsScreen(),
                    ),
                  ).then((_) => setState(() {}));
                },
                icon: const Icon(Icons.settings_rounded, color: Colors.white),
              ),
              IconButton(
                tooltip: 'Logout',
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: PETROL_DARK,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _buildHeader(
                  parentName: parentName,
                  relation: relation,
                  childrenCount: children.length,
                  criticalCount: criticalCount,
                ),
                const SizedBox(height: 16),
                _buildSummaryRow(
                  childrenCount: children.length,
                  criticalCount: criticalCount,
                ),
                const SizedBox(height: 12),
                _buildPreferenceSummary(
                  notificationsEnabled: notificationsEnabled,
                  criticalAlertsOnly: criticalAlertsOnly,
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Quick Access'),
                const SizedBox(height: 12),
                _buildQuickAccess(context, children),
                const SizedBox(height: 20),
                _buildSectionTitle('Children Status'),
                const SizedBox(height: 12),
                _buildChildrenCards(context, children),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader({
    required String parentName,
    required String relation,
    required int childrenCount,
    required int criticalCount,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [PETROL_DARK, PETROL],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: PETROL_DARK.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parentName.isEmpty ? 'Family Monitoring' : parentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  relation.isEmpty
                      ? 'Track your children, alerts, and daily health status'
                      : '$relation • Family follow-up account',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip('$childrenCount linked'),
                    _chip('$criticalCount critical'),
                    _chip('Real-time follow up'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required int childrenCount,
    required int criticalCount,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _smallMetric(
              title: 'Children',
              value: '$childrenCount',
              icon: Icons.child_care_rounded,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _smallMetric(
              title: 'Critical',
              value: '$criticalCount',
              icon: Icons.warning_amber_rounded,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSummary({
    required bool notificationsEnabled,
    required bool criticalAlertsOnly,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _prefTile(
                icon: Icons.notifications_active_rounded,
                title: 'Notifications',
                value: notificationsEnabled ? 'Enabled' : 'Disabled',
                color: notificationsEnabled ? Colors.green : Colors.redAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _prefTile(
                icon: Icons.warning_amber_rounded,
                title: 'Critical Only',
                value: criticalAlertsOnly ? 'Yes' : 'No',
                color: criticalAlertsOnly ? Colors.orange : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: PETROL_DARK,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _prefTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: PETROL_DARK,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: PETROL_DARK,
        ),
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context, List<dynamic> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.28,
        children: [
          _quickCard(
            title: 'Alerts',
            subtitle: 'Critical cases first',
            icon: Icons.notifications_active_rounded,
            color: Colors.redAccent,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connect this button to alerts screen'),
                ),
              );
            },
          ),
          _quickCard(
            title: 'Reports',
            subtitle: 'Medical PDF / summaries',
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.deepPurple,
            onTap: () {
              if (children.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      PatientDetailForDoctorScreen(patient: children.first),
                ),
              );
            },
          ),
          _quickCard(
            title: 'Doctor',
            subtitle: 'Call or message doctor',
            icon: Icons.local_hospital_rounded,
            color: Colors.green,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Connect this button to doctor contact screen'),
                ),
              );
            },
          ),
          _quickCard(
            title: 'Settings',
            subtitle: 'Profile and preferences',
            icon: Icons.settings_rounded,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ParentSettingsScreen(),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
    );
  }

  Widget _quickCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: PETROL_DARK,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildrenCards(BuildContext context, List<dynamic> children) {
    if (children.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: PETROL.withOpacity(0.10),
              child: const Icon(
                Icons.child_friendly_rounded,
                color: PETROL_DARK,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No linked children yet',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: PETROL_DARK,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Once a patient is connected to this parent account, the child profile will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    return Column(
      children: children.map((child) {
        final hr = _readAny(child, ['heartRate']);
        final spo2 = _readAny(child, ['spo2']);
        final temp = _readAny(child, ['temperature']);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: PETROL.withOpacity(0.10),
                    child: const Icon(Icons.person_rounded, color: PETROL_DARK),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _childName(child),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: PETROL_DARK,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _childSubtitle(child),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PatientDetailForDoctorScreen(patient: child),
                        ),
                      );
                    },
                    child: const Text('Report'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _vitalMiniCard(
                      label: 'HR',
                      value: _reading(hr, ' bpm'),
                      icon: Icons.favorite_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _vitalMiniCard(
                      label: 'SpO2',
                      value: _reading(spo2, '%'),
                      icon: Icons.air_rounded,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _vitalMiniCard(
                      label: 'Temp',
                      value: _reading(temp, '°C'),
                      icon: Icons.thermostat_rounded,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _vitalMiniCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
              color: PETROL_DARK,
            ),
          ),
        ],
      ),
    );
  }
}