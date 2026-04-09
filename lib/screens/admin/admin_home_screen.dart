import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admit_patient_screen.dart';
import 'department_management_screen.dart';
import 'dispatch_dashboard_screen.dart';
import 'emergency_queue_screen.dart';
import 'hospital_people_list_screen.dart';
import 'hospital_profile_screen.dart';
import 'staff_approval_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _loading = true;
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _hospitalData;
  String _institutionId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        setState(() => _loading = false);
        return;
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? <String, dynamic>{};

      final institutionId = (userData['institutionId'] ?? '').toString();
      Map<String, dynamic>? hospitalData;

      if (institutionId.isNotEmpty) {
        final hospitalDoc =
            await _firestore.collection('institutions').doc(institutionId).get();
        hospitalData = hospitalDoc.data();
      }

      if (mounted) {
        setState(() {
          _userData = userData;
          _institutionId = institutionId;
          _hospitalData = hospitalData;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load hospital dashboard: $e')),
        );
      }
    }
  }

  Future<int> _countUsersByRole(String role, {bool onlyToday = false}) async {
    if (_institutionId.isEmpty) return 0;

    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .where('institutionId', isEqualTo: _institutionId)
        .where('role', isEqualTo: role);

    if (onlyToday) {
      final now = DateTime.now();
      final dayKey =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      query = query.where('arrivalDayKey', isEqualTo: dayKey);
    }

    final snapshot = await query.get();
    return snapshot.docs.length;
  }

  Future<int> _countPendingRequests() async {
    if (_institutionId.isEmpty) return 0;
    final snapshot = await _firestore
        .collection('staff_requests')
        .where('institutionId', isEqualTo: _institutionId)
        .where('status', isEqualTo: 'pending')
        .get();
    return snapshot.docs.length;
  }

  Future<int> _countEmergencies() async {
    if (_institutionId.isEmpty) return 0;
    final snapshot = await _firestore
        .collection('dispatch_cases')
        .where('institutionId', isEqualTo: _institutionId)
        .where('status', isNotEqualTo: 'closed')
        .get();

    return snapshot.docs.where((doc) {
      final data = doc.data();
      final severity = (data['severity'] ?? '').toString().toLowerCase();
      final priority = (data['priority'] ?? '').toString().toLowerCase();
      return severity == 'emergency' || priority == 'emergency';
    }).length;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadRecentAlerts() async {
    if (_institutionId.isEmpty) return [];
    final snapshot = await _firestore
        .collection('alerts')
        .where('institutionId', isEqualTo: _institutionId)
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();
    return snapshot.docs;
  }

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then((_) {
      _loadData();
      setState(() {});
    });
  }

  String get _hospitalName {
    return (_hospitalData?['name'] ??
            _hospitalData?['hospitalName'] ??
            _userData?['institutionName'] ??
            'Hospital')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HospitalHeaderCard(
              name: _hospitalName,
              institutionId: _institutionId,
              city: (_hospitalData?['city'] ?? _hospitalData?['hospitalCity'] ?? '-')
                  .toString(),
              adminName: (_userData?['name'] ?? _userData?['fullName'] ?? 'Admin')
                  .toString(),
              onProfileTap: () => _push(const HospitalProfileScreen()),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<int>>(
              future: Future.wait<int>([
                _countUsersByRole('doctor'),
                _countUsersByRole('nurse'),
                _countUsersByRole('patient', onlyToday: true),
                _countPendingRequests(),
                _countEmergencies(),
              ]),
              builder: (context, snapshot) {
                final values = snapshot.data ?? [0, 0, 0, 0, 0];
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.25,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _StatsCard(
                      title: 'Doctors',
                      value: values[0].toString(),
                      icon: Icons.medical_services_outlined,
                    ),
                    _StatsCard(
                      title: 'Nurses',
                      value: values[1].toString(),
                      icon: Icons.local_hospital_outlined,
                    ),
                    _StatsCard(
                      title: 'Patients Today',
                      value: values[2].toString(),
                      icon: Icons.groups_outlined,
                    ),
                    _StatsCard(
                      title: 'Pending Approvals',
                      value: values[3].toString(),
                      icon: Icons.approval_outlined,
                    ),
                    _StatsCard(
                      title: 'Emergency Cases',
                      value: values[4].toString(),
                      icon: Icons.warning_amber_rounded,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionChipButton(
                  icon: Icons.person_add_alt_1,
                  label: 'Admit Patient',
                  onTap: () => _push(
                    AdmitPatientScreen(
                      institutionId: _institutionId,
                      institutionName: _hospitalName,
                    ),
                  ),
                ),
                _ActionChipButton(
                  icon: Icons.approval,
                  label: 'Staff Approvals',
                  onTap: () => _push(
                    StaffApprovalScreen(institutionId: _institutionId),
                  ),
                ),
                _ActionChipButton(
                  icon: Icons.account_tree_outlined,
                  label: 'Departments',
                  onTap: () => _push(
                    DepartmentManagementScreen(institutionId: _institutionId),
                  ),
                ),
                _ActionChipButton(
                  icon: Icons.emergency,
                  label: 'Emergency Queue',
                  onTap: () => _push(const EmergencyQueueScreen()),
                ),
                _ActionChipButton(
                  icon: Icons.space_dashboard_outlined,
                  label: 'Dispatch Dashboard',
                  onTap: () => _push(
                    DispatchDashboardScreen(institutionId: _institutionId),
                  ),
                ),
                _ActionChipButton(
                  icon: Icons.badge_outlined,
                  label: 'Doctors',
                  onTap: () => _push(
                    HospitalPeopleListScreen(
                      institutionId: _institutionId,
                      title: 'Doctors',
                      roleFilter: 'doctor',
                    ),
                  ),
                ),
                _ActionChipButton(
                  icon: Icons.health_and_safety_outlined,
                  label: 'Nurses',
                  onTap: () => _push(
                    HospitalPeopleListScreen(
                      institutionId: _institutionId,
                      title: 'Nurses',
                      roleFilter: 'nurse',
                    ),
                  ),
                ),
                _ActionChipButton(
                  icon: Icons.groups_2_outlined,
                  label: 'Patients Today',
                  onTap: () => _push(
                    HospitalPeopleListScreen(
                      institutionId: _institutionId,
                      title: 'Patients Today',
                      roleFilter: 'patient',
                      onlyToday: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Latest Alerts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              future: _loadRecentAlerts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data ?? [];
                if (docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No alerts yet.'),
                    ),
                  );
                }
                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final title = (data['title'] ?? data['type'] ?? 'Alert').toString();
                    final subtitle = (data['message'] ?? data['description'] ?? '-')
                        .toString();
                    final patient =
                        (data['patientName'] ?? data['patientId'] ?? '').toString();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.notifications_active_outlined),
                        ),
                        title: Text(title),
                        subtitle: Text(
                          patient.isEmpty ? subtitle : '$patient\n$subtitle',
                        ),
                        isThreeLine: patient.isNotEmpty,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HospitalHeaderCard extends StatelessWidget {
  final String name;
  final String institutionId;
  final String city;
  final String adminName;
  final VoidCallback onProfileTap;

  const _HospitalHeaderCard({
    required this.name,
    required this.institutionId,
    required this.city,
    required this.adminName,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  child: Icon(Icons.local_hospital, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Hospital ID: ${institutionId.isEmpty ? '-' : institutionId}'),
                      Text('City: $city'),
                      Text('Admin: $adminName'),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onProfileTap,
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(title),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
