import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/patient.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
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

  Map<String, String> _parsePatientQr(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) throw Exception('Patient QR is empty');

    try {
      final decoded = jsonDecode(value);
      if (decoded is Map && decoded['type'] == 'patient_qr') {
        final patientId = (decoded['patientId'] ?? '').toString().trim();
        final patientName = (decoded['patientName'] ?? '').toString().trim();
        if (patientId.isNotEmpty) {
          return {
            'patientId': patientId,
            'patientName': patientName.isEmpty ? 'Patient' : patientName,
          };
        }
      }
    } catch (_) {}

    return {
      'patientId': value,
      'patientName': 'Patient',
    };
  }

  Future<void> _linkPatientByQr(String rawValue) async {
    try {
      final qr = _parsePatientQr(rawValue);
      final patientId = qr['patientId']!;
      var patientName = qr['patientName']!;

      await FirebaseFirestore.instance
          .collection('care_links')
          .doc('${_uid}_$patientId')
          .set({
        'patientId': patientId,
        'patientName': patientName,
        'linkedUserId': _uid,
        'linkedUserRole': 'parent',
        'parentId': _uid,
        'status': 'approved',
        'relationshipLabel': 'family_patient',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();
      final patientData = patientDoc.data();
      if (patientData == null) {
        await FirebaseFirestore.instance
            .collection('care_links')
            .doc('${_uid}_$patientId')
            .delete();
        throw Exception('Patient not found');
      }

      patientName = (patientData['name'] ?? patientData['fullName'] ?? patientName)
          .toString();

      await FirebaseFirestore.instance
          .collection('care_links')
          .doc('${_uid}_$patientId')
          .set({
        'patientName': patientName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(_uid).set({
        'linkedPatients': FieldValue.arrayUnion([patientId]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$patientName linked successfully')),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to link patient: $e')),
      );
    }
  }

  Future<void> _scanPatientQr() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _ParentQrScannerPage()),
    );

    if (result == null || result.trim().isEmpty) return;
    await _linkPatientByQr(result);
  }

  Stream<List<Patient>> _linkedPatientsStream() {
    return FirebaseFirestore.instance
        .collection('care_links')
        .where('linkedUserId', isEqualTo: _uid)
        .where('linkedUserRole', isEqualTo: 'parent')
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .asyncMap((snapshot) async {
      final patients = <Patient>[];
      for (final doc in snapshot.docs) {
        final patientId = (doc.data()['patientId'] ?? '').toString();
        if (patientId.isEmpty) continue;

        final patientDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(patientId)
            .get();
        final data = patientDoc.data();
        if (data == null) continue;

        patients.add(Patient.fromJson({'id': patientDoc.id, ...data}));
      }
      return patients;
    });
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

  String _childName(dynamic child) {
    final name = _readAny(child, ['name']);
    return (name == null || name.toString().trim().isEmpty)
        ? 'Unknown Child'
        : name.toString();
  }

  String _childSubtitle(dynamic child) {
    final lang = AppLocalizations.of(context);
    final age = _readAny(child, ['age']);
    final condition = _readAny(child, ['condition']);

    final parts = <String>[];
    if (age != null) parts.add('${lang.translate('age')}: $age');
    if (condition != null && condition.toString().trim().isNotEmpty) {
      parts.add(condition.toString());
    }

    return parts.isEmpty ? lang.translate('follow_up_profile') : parts.join(' • ');
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
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchParentData(),
      builder: (context, parentSnap) {
        final parentData = parentSnap.data ?? {};
        final parentName = (parentData['name'] ?? '').toString().trim();
        final relation = (parentData['relation'] ?? '').toString().trim();
        final notificationsEnabled = parentData['notificationsEnabled'] == true;
        final criticalAlertsOnly = parentData['criticalAlertsOnly'] == true;

        return StreamBuilder<List<Patient>>(
          stream: _linkedPatientsStream(),
          builder: (context, patientSnap) {
            final lang = AppLocalizations.of(context);
            final children = patientSnap.data ?? const <Patient>[];
            final criticalCount = _criticalCount(children);

            return Scaffold(
              backgroundColor: lightBg,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: petrolDark,
                title: Text(
                  parentName.isEmpty ? lang.translate('parent_dashboard') : parentName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: lang.translate('scan_patient_qr'),
                    onPressed: _scanPatientQr,
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    tooltip: lang.translate('settings'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ParentSettingsScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    icon:
                        const Icon(Icons.settings_rounded, color: Colors.white),
                  ),
                  IconButton(
                    tooltip: lang.translate('logout'),
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  ),
                ],
              ),
              body: RefreshIndicator(
                color: petrolDark,
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
                    _buildSectionTitle(lang.translate('quick_access')),
                    const SizedBox(height: 12),
                    _buildQuickAccess(context, children),
                    const SizedBox(height: 20),
                    _buildSectionTitle(lang.translate('children_status')),
                    const SizedBox(height: 12),
                    if (patientSnap.connectionState == ConnectionState.waiting)
                      const Center(child: CircularProgressIndicator())
                    else
                      _buildChildrenCards(context, children),
                  ],
                ),
              ),
            );
          },
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
          colors: [petrolDark, petrol],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: petrolDark.withValues(alpha: 0.18),
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
              color: petrolDark,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (ctx) {
                  final l = AppLocalizations.of(ctx);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parentName.isEmpty ? l.translate('family_monitoring') : parentName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        relation.isEmpty
                            ? l.translate('parent_track_subtitle')
                            : '$relation • ${l.translate('family_follow_up')}',
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
                          _chip('$childrenCount ${l.translate('linked')}'),
                          _chip('$criticalCount ${l.translate('critical').toLowerCase()}'),
                          _chip(l.translate('real_time_follow_up')),
                        ],
                      ),
                    ],
                  );
                }),
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
        color: Colors.white.withValues(alpha: 0.16),
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
    final lang = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _smallMetric(
              title: lang.translate('children'),
              value: '$childrenCount',
              icon: Icons.child_care_rounded,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _smallMetric(
              title: lang.translate('critical'),
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Builder(builder: (ctx) {
          final l = AppLocalizations.of(ctx);
          return Row(
            children: [
              Expanded(
                child: _prefTile(
                  icon: Icons.notifications_active_rounded,
                  title: l.translate('notifications'),
                  value: notificationsEnabled ? l.translate('enabled') : l.translate('disabled'),
                  color: notificationsEnabled ? Colors.green : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _prefTile(
                  icon: Icons.warning_amber_rounded,
                  title: l.translate('critical_only'),
                  value: criticalAlertsOnly ? l.translate('yes') : l.translate('no'),
                  color: criticalAlertsOnly ? Colors.orange : Colors.blue,
                ),
              ),
            ],
          );
        }),
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
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
                    color: petrolDark,
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
          backgroundColor: color.withValues(alpha: 0.12),
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
                  color: petrolDark,
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
          color: petrolDark,
        ),
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context, List<dynamic> children) {
    final lang = AppLocalizations.of(context);
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
            title: lang.translate('scan_qr'),
            subtitle: lang.translate('link_patient_subtitle'),
            icon: Icons.qr_code_scanner_rounded,
            color: Colors.teal,
            onTap: _scanPatientQr,
          ),
          _quickCard(
            title: lang.translate('alerts'),
            subtitle: lang.translate('critical_cases_first'),
            icon: Icons.notifications_active_rounded,
            color: Colors.redAccent,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.translate('alerts'))),
              );
            },
          ),
          _quickCard(
            title: lang.translate('reports'),
            subtitle: lang.translate('medical_pdf_subtitle'),
            icon: Icons.picture_as_pdf_rounded,
            color: Colors.deepPurple,
            onTap: () {
              if (children.isEmpty) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PatientDetailForDoctorScreen(
                    patient: children.first as Patient,
                  ),
                ),
              );
            },
          ),
          _quickCard(
            title: lang.translate('doctor'),
            subtitle: lang.translate('call_doctor_subtitle'),
            icon: Icons.local_hospital_rounded,
            color: Colors.green,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.translate('doctor'))),
              );
            },
          ),
          _quickCard(
            title: lang.translate('settings'),
            subtitle: lang.translate('profile_preferences_subtitle'),
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
          border: Border.all(color: color.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
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
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: petrolDark,
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
    final lang = AppLocalizations.of(context);
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
              backgroundColor: petrol.withValues(alpha: 0.10),
              child: const Icon(
                Icons.child_friendly_rounded,
                color: petrolDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              lang.translate('no_linked_children'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: petrolDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              lang.translate('no_linked_children_desc'),
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
                color: Colors.black.withValues(alpha: 0.035),
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
                    backgroundColor: petrol.withValues(alpha: 0.10),
                    child: const Icon(Icons.person_rounded, color: petrolDark),
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
                            color: petrolDark,
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
                              PatientDetailForDoctorScreen(
                            patient: child as Patient,
                          ),
                        ),
                      );
                    },
                    child: Text(lang.translate('report_button')),
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
        color: color.withValues(alpha: 0.08),
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
              color: petrolDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentQrScannerPage extends StatefulWidget {
  const _ParentQrScannerPage();

  @override
  State<_ParentQrScannerPage> createState() => _ParentQrScannerPageState();
}

class _ParentQrScannerPageState extends State<_ParentQrScannerPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('scan_patient_qr')),
        backgroundColor: petrolDark,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) return;
              final codes = capture.barcodes;
              if (codes.isEmpty) return;

              final value = codes.first.rawValue ?? '';
              if (value.trim().isEmpty) return;

              _handled = true;
              Navigator.of(context).pop(value.trim());
            },
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
