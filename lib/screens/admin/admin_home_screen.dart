import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants.dart';
import 'hospital_people_list_screen.dart';
import 'hospital_profile_screen.dart';
import 'staff_approval_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  Future<Map<String, dynamic>?> _loadAdminAndInstitution() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final db = FirebaseFirestore.instance;

    final userDoc = await db.collection('users').doc(uid).get();
    final userData = userDoc.data();
    if (userData == null) return null;

    final institutionId = (userData['institutionId'] ?? '').toString();
    if (institutionId.isEmpty) {
      return {
        'user': userData,
        'institution': null,
        'institutionId': '',
      };
    }

    final institutionDoc =
        await db.collection('institutions').doc(institutionId).get();

    return {
      'user': userData,
      'institution': institutionDoc.data(),
      'institutionId': institutionId,
    };
  }

  Future<Map<String, int>> _loadCounts(String institutionId) async {
    final db = FirebaseFirestore.instance;

    final usersSnap = await db
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .get();

    final pendingSnap = await db
        .collection('staff_requests')
        .where('institutionId', isEqualTo: institutionId)
        .where('approvalStatus', isEqualTo: 'pending')
        .get();

    final alertsSnap = await db
        .collectionGroup('alerts')
        .where('institutionId', isEqualTo: institutionId)
        .get()
        .catchError((_) => null);

    int doctors = 0;
    int nurses = 0;
    int staff = 0;
    int patientsToday = 0;

    final todayKey = _todayKey();

    for (final doc in usersSnap.docs) {
      final data = doc.data();
      final role = (data['role'] ?? '').toString().toLowerCase();

      if (role == 'doctor') doctors++;
      if (role == 'nurse') nurses++;
      if (role == 'staff') staff++;

      if (role == 'patient' &&
          (data['arrivalDayKey'] ?? '').toString() == todayKey) {
        patientsToday++;
      }
    }

    return {
      'doctors': doctors,
      'nurses': nurses,
      'staff': staff,
      'patientsToday': patientsToday,
      'pendingApprovals': pendingSnap.docs.length,
      'alertsToday': alertsSnap == null ? 0 : alertsSnap.docs.length,
    };
  }

  static String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _loadRecentPending(
    String institutionId,
  ) async {
    final snap = await FirebaseFirestore.instance
        .collection('staff_requests')
        .where('institutionId', isEqualTo: institutionId)
        .where('approvalStatus', isEqualTo: 'pending')
        .limit(5)
        .get();

    return snap.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _loadRecentAlerts(String institutionId) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collectionGroup('alerts')
          .where('institutionId', isEqualTo: institutionId)
          .limit(5)
          .get();

      return snap.docs;
    } catch (_) {
      return [];
    }
  }

  void _copyHospitalId(BuildContext context, String hospitalId) {
    Clipboard.setData(ClipboardData(text: hospitalId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hospital ID copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Hospital Dashboard'),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadAdminAndInstitution(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bundle = snapshot.data;
          if (bundle == null) {
            return const Center(
              child: Text(
                'Unable to load hospital data.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }

          final user =
              (bundle['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
          final institution = (bundle['institution'] as Map<String, dynamic>?) ??
              <String, dynamic>{};
          final institutionId = (bundle['institutionId'] ?? '').toString();

          if (institutionId.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'No hospital is linked to this account yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HospitalHeaderCard(
                  hospitalName:
                      (institution['institutionName'] ?? 'Unknown Hospital')
                          .toString(),
                  hospitalId: institutionId,
                  adminName: (user['name'] ?? '-').toString(),
                  city: (institution['institutionCity'] ?? '-').toString(),
                  isActive: (institution['isActive'] ?? true) == true,
                  onCopy: () => _copyHospitalId(context, institutionId),
                ),
                const SizedBox(height: 16),
                FutureBuilder<Map<String, int>>(
                  future: _loadCounts(institutionId),
                  builder: (context, countSnapshot) {
                    final counts = countSnapshot.data ??
                        {
                          'doctors': 0,
                          'nurses': 0,
                          'staff': 0,
                          'patientsToday': 0,
                          'pendingApprovals': 0,
                          'alertsToday': 0,
                        };

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle('Overview'),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _StatCard(
                              title: 'Doctors',
                              value: '${counts['doctors']}',
                              icon: Icons.medical_services,
                            ),
                            _StatCard(
                              title: 'Nurses',
                              value: '${counts['nurses']}',
                              icon: Icons.local_hospital,
                            ),
                            _StatCard(
                              title: 'Staff',
                              value: '${counts['staff']}',
                              icon: Icons.badge,
                            ),
                            _StatCard(
                              title: 'Patients Today',
                              value: '${counts['patientsToday']}',
                              icon: Icons.people_alt,
                            ),
                            _StatCard(
                              title: 'Pending Approvals',
                              value: '${counts['pendingApprovals']}',
                              icon: Icons.pending_actions,
                            ),
                            _StatCard(
                              title: 'Alerts',
                              value: '${counts['alertsToday']}',
                              icon: Icons.warning_amber_rounded,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Quick Actions'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ActionButton(
                      icon: Icons.apartment,
                      label: 'Hospital Profile',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HospitalProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      icon: Icons.verified_user,
                      label: 'Approve Staff',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StaffApprovalScreen(
                              institutionId: institutionId,
                            ),
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      icon: Icons.person_search,
                      label: 'Doctors',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HospitalPeopleListScreen(
                              institutionId: institutionId,
                              title: 'Doctors',
                              roleFilter: 'doctor',
                            ),
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      icon: Icons.health_and_safety,
                      label: 'Nurses',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HospitalPeopleListScreen(
                              institutionId: institutionId,
                              title: 'Nurses',
                              roleFilter: 'nurse',
                            ),
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      icon: Icons.groups_2,
                      label: 'Staff',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HospitalPeopleListScreen(
                              institutionId: institutionId,
                              title: 'Staff',
                              roleFilter: 'staff',
                            ),
                          ),
                        );
                      },
                    ),
                    _ActionButton(
                      icon: Icons.elderly,
                      label: 'Today Patients',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HospitalPeopleListScreen(
                              institutionId: institutionId,
                              title: 'Today Patients',
                              roleFilter: 'patient',
                              onlyToday: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Pending Requests'),
                const SizedBox(height: 12),
                FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                  future: _loadRecentPending(institutionId),
                  builder: (context, pendingSnapshot) {
                    if (pendingSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = pendingSnapshot.data ?? [];
                    if (docs.isEmpty) {
                      return const _EmptyCard(
                        text: 'No pending staff approvals right now.',
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data();
                        return _MiniInfoCard(
                          title: (data['name'] ?? 'Unknown').toString(),
                          subtitle:
                              '${data['medicalRole'] ?? data['staffRole'] ?? 'Staff'} • ${data['departmentName'] ?? '-'}',
                          trailing: 'Pending',
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const _SectionTitle('Recent Alerts'),
                const SizedBox(height: 12),
                FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
                  future: _loadRecentAlerts(institutionId),
                  builder: (context, alertSnapshot) {
                    if (alertSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = alertSnapshot.data ?? [];
                    if (docs.isEmpty) {
                      return const _EmptyCard(
                        text: 'No recent alerts found.',
                      );
                    }

                    return Column(
                      children: docs.map((doc) {
                        final data = doc.data();
                        final title = (data['title'] ??
                                data['alertType'] ??
                                data['type'] ??
                                'Alert')
                            .toString();
                        final subtitle = (data['message'] ??
                                data['description'] ??
                                data['status'] ??
                                '-')
                            .toString();

                        return _MiniInfoCard(
                          title: title,
                          subtitle: subtitle,
                          trailing: (data['priority'] ??
                                  data['priorityLevel'] ??
                                  'Info')
                              .toString(),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HospitalHeaderCard extends StatelessWidget {
  final String hospitalName;
  final String hospitalId;
  final String adminName;
  final String city;
  final bool isActive;
  final VoidCallback onCopy;

  const _HospitalHeaderCard({
    required this.hospitalName,
    required this.hospitalId,
    required this.adminName,
    required this.city,
    required this.isActive,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [PETROL_DARK, PETROL],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(Icons.local_hospital, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hospitalName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.shade600 : Colors.orange,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'PENDING',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _headerRow('Hospital ID', hospitalId, onCopy: onCopy),
          const SizedBox(height: 10),
          _headerRow('Admin', adminName),
          const SizedBox(height: 10),
          _headerRow('City', city),
        ],
      ),
    );
  }

  Widget _headerRow(String label, String value, {VoidCallback? onCopy}) {
    return Row(
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (onCopy != null)
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy, color: Colors.white, size: 20),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: PETROL_DARK),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: PETROL_DARK,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: LIGHT_BG,
                child: Icon(icon, color: PETROL_DARK),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: PETROL_DARK,
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

class _MiniInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;

  const _MiniInfoCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: LIGHT_BG,
            child: Icon(Icons.info_outline, color: PETROL_DARK),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: PETROL_DARK,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: LIGHT_BG,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: PETROL_DARK,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String text;

  const _EmptyCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: PETROL_DARK,
      ),
    );
  }
}