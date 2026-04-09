import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
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
  late Future<_HospitalDashboardData?> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadDashboard();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadDashboard();
    });
    await _future;
  }

  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<_HospitalDashboardData?> _loadDashboard() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final db = FirebaseFirestore.instance;

    final userDoc = await db.collection('users').doc(uid).get();
    final userData = userDoc.data();
    if (userData == null) return null;

    final institutionId = (userData['institutionId'] ?? '').toString();
    if (institutionId.isEmpty) {
      return _HospitalDashboardData(
        institutionId: '',
        hospitalName: (userData['institutionName'] ?? 'Hospital').toString(),
        hospitalCity: (userData['institutionCity'] ?? '').toString(),
        adminName: (userData['name'] ?? '').toString(),
        counts: const {},
        pendingDocs: const [],
        recentPatientDocs: const [],
      );
    }

    final institutionDoc =
        await db.collection('institutions').doc(institutionId).get();
    final institutionData = institutionDoc.data() ?? {};

    final doctorsFuture = db
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .where('role', isEqualTo: 'doctor')
        .get();

    final nursesFuture = db
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .where('role', isEqualTo: 'nurse')
        .get();

    final staffFuture = db
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .where('role', isEqualTo: 'staff')
        .get();

    final todayPatientsFuture = db
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .where('role', isEqualTo: 'patient')
        .where('arrivalDayKey', isEqualTo: _todayKey())
        .get();

    final pendingFuture = db
        .collection('staff_requests')
        .where('institutionId', isEqualTo: institutionId)
        .where('approvalStatus', isEqualTo: 'pending')
        .get();

    final departmentsFuture = db
        .collection('departments')
        .where('institutionId', isEqualTo: institutionId)
        .get();

    final admissionsFuture = db
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .where('role', isEqualTo: 'patient')
        .where('arrivalDayKey', isEqualTo: _todayKey())
        .get();

    final results = await Future.wait([
      doctorsFuture,
      nursesFuture,
      staffFuture,
      todayPatientsFuture,
      pendingFuture,
      departmentsFuture,
      admissionsFuture,
    ]);

    final doctorsSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
    final nursesSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final staffSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final todayPatientsSnap = results[3] as QuerySnapshot<Map<String, dynamic>>;
    final pendingSnap = results[4] as QuerySnapshot<Map<String, dynamic>>;
    final departmentsSnap = results[5] as QuerySnapshot<Map<String, dynamic>>;
    final admissionsSnap = results[6] as QuerySnapshot<Map<String, dynamic>>;

    return _HospitalDashboardData(
      institutionId: institutionId,
      hospitalName:
          (institutionData['institutionName'] ??
                  userData['institutionName'] ??
                  'Hospital')
              .toString(),
      hospitalCity:
          (institutionData['institutionCity'] ?? userData['institutionCity'] ?? '')
              .toString(),
      adminName: (userData['name'] ?? '').toString(),
      counts: {
        'doctors': doctorsSnap.docs.length,
        'nurses': nursesSnap.docs.length,
        'staff': staffSnap.docs.length,
        'todayPatients': todayPatientsSnap.docs.length,
        'pending': pendingSnap.docs.length,
        'departments': departmentsSnap.docs.length,
        'todayAdmissions': admissionsSnap.docs.length,
      },
      pendingDocs: pendingSnap.docs.take(5).toList(),
      recentPatientDocs: admissionsSnap.docs.take(5).toList(),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      body: SafeArea(
        child: FutureBuilder<_HospitalDashboardData?>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snapshot.data;
            if (data == null) {
              return _DashboardErrorView(onRetry: _refresh);
            }

            if (data.institutionId.isEmpty) {
              return _NoInstitutionView(onRefresh: _refresh);
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _HeaderCard(
                    hospitalName: data.hospitalName,
                    hospitalCity: data.hospitalCity,
                    adminName: data.adminName,
                    institutionId: data.institutionId,
                    onProfileTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HospitalProfileScreen(),
                        ),
                      ).then((_) => _refresh());
                    },
                    onLogoutTap: _logout,
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle('Hospital Overview'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.22,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _StatCard(
                        title: 'Doctors',
                        value: '${data.counts['doctors'] ?? 0}',
                        icon: Icons.medical_services_rounded,
                        color: PETROL_DARK,
                      ),
                      _StatCard(
                        title: 'Nurses',
                        value: '${data.counts['nurses'] ?? 0}',
                        icon: Icons.health_and_safety_rounded,
                        color: PETROL,
                      ),
                      _StatCard(
                        title: 'Staff',
                        value: '${data.counts['staff'] ?? 0}',
                        icon: Icons.badge_rounded,
                        color: ACCENT_ORANGE,
                      ),
                      _StatCard(
                        title: 'Patients Today',
                        value: '${data.counts['todayPatients'] ?? 0}',
                        icon: Icons.personal_injury_rounded,
                        color: ACCENT_YELLOW,
                      ),
                      _StatCard(
                        title: 'Pending Requests',
                        value: '${data.counts['pending'] ?? 0}',
                        icon: Icons.pending_actions_rounded,
                        color: Colors.deepOrange,
                      ),
                      _StatCard(
                        title: 'Departments',
                        value: '${data.counts['departments'] ?? 0}',
                        icon: Icons.apartment_rounded,
                        color: Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Quick Actions'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _ActionButton(
                        icon: Icons.business_rounded,
                        label: 'Hospital Profile',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HospitalProfileScreen(),
                            ),
                          ).then((_) => _refresh());
                        },
                      ),
                      _ActionButton(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Approve Staff',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StaffApprovalScreen(
                                institutionId: data.institutionId,
                              ),
                            ),
                          ).then((_) => _refresh());
                        },
                      ),
                      _ActionButton(
                        icon: Icons.groups_rounded,
                        label: 'Doctors',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HospitalPeopleListScreen(
                                institutionId: data.institutionId,
                                title: 'Doctors',
                                roleFilter: 'doctor',
                              ),
                            ),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.local_hospital_rounded,
                        label: 'Nurses',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HospitalPeopleListScreen(
                                institutionId: data.institutionId,
                                title: 'Nurses',
                                roleFilter: 'nurse',
                              ),
                            ),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.badge_rounded,
                        label: 'Staff',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HospitalPeopleListScreen(
                                institutionId: data.institutionId,
                                title: 'Staff',
                                roleFilter: 'staff',
                              ),
                            ),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.elderly_rounded,
                        label: 'Today Patients',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HospitalPeopleListScreen(
                                institutionId: data.institutionId,
                                title: 'Today Patients',
                                roleFilter: 'patient',
                                onlyToday: true,
                              ),
                            ),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.domain_add_rounded,
                        label: 'Departments',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DepartmentManagementScreen(),
                            ),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.route_rounded,
                        label: 'Dispatch',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DispatchDashboardScreen(),
                            ),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.emergency_rounded,
                        label: 'Emergency Queue',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmergencyQueueScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Pending Staff Requests'),
                  const SizedBox(height: 12),
                  if (data.pendingDocs.isEmpty)
                    const _EmptyCard(
                      text: 'No pending staff approvals right now.',
                    )
                  else
                    ...data.pendingDocs.map(
                      (doc) => _MiniInfoCard(
                        title: (doc.data()['name'] ?? 'Unknown').toString(),
                        subtitle:
                            '${doc.data()['medicalRole'] ?? doc.data()['staffRole'] ?? 'Staff'} • '
                            '${doc.data()['departmentName'] ?? 'No department'}',
                        trailing: 'Pending',
                      ),
                    ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Today Admissions'),
                  const SizedBox(height: 12),
                  if (data.recentPatientDocs.isEmpty)
                    const _EmptyCard(
                      text: 'No patients admitted today.',
                    )
                  else
                    ...data.recentPatientDocs.map(
                      (doc) => _MiniInfoCard(
                        title: (doc.data()['name'] ?? 'Unknown patient').toString(),
                        subtitle:
                            'Patient ID: ${(doc.data()['patientId'] ?? '--').toString()}'
                            ' • ${(doc.data()['email'] ?? '--').toString()}',
                        trailing: 'Today',
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HospitalDashboardData {
  final String institutionId;
  final String hospitalName;
  final String hospitalCity;
  final String adminName;
  final Map<String, int> counts;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingDocs;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> recentPatientDocs;

  _HospitalDashboardData({
    required this.institutionId,
    required this.hospitalName,
    required this.hospitalCity,
    required this.adminName,
    required this.counts,
    required this.pendingDocs,
    required this.recentPatientDocs,
  });
}

class _HeaderCard extends StatelessWidget {
  final String hospitalName;
  final String hospitalCity;
  final String adminName;
  final String institutionId;
  final VoidCallback onProfileTap;
  final VoidCallback onLogoutTap;

  const _HeaderCard({
    required this.hospitalName,
    required this.hospitalCity,
    required this.adminName,
    required this.institutionId,
    required this.onProfileTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [PETROL_DARK, PETROL],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
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
                child: Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospitalName.isEmpty ? 'Hospital Dashboard' : hospitalName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hospitalCity.isEmpty
                          ? 'Main hospital account'
                          : hospitalCity,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (v) {
                  if (v == 'profile') onProfileTap();
                  if (v == 'logout') onLogoutTap();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'profile',
                    child: Text('Hospital Profile'),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _headerChip(Icons.badge_outlined, 'ID: $institutionId'),
              _headerChip(
                Icons.person_outline_rounded,
                adminName.isEmpty ? 'Hospital Account' : adminName,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onProfileTap,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
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
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: (MediaQuery.of(context).size.width - 42) / 2,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: PETROL.withOpacity(0.10),
                child: Icon(icon, color: PETROL_DARK),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
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
            backgroundColor: Color(0x14006D77),
            child: Icon(Icons.person_outline_rounded, color: PETROL_DARK),
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: PETROL.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              trailing,
              style: const TextStyle(
                color: PETROL_DARK,
                fontWeight: FontWeight.w700,
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
          color: Colors.black54,
          fontWeight: FontWeight.w600,
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
        color: Colors.black87,
      ),
    );
  }
}

class _DashboardErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _DashboardErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 54, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Failed to load hospital dashboard.',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: PETROL_DARK,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoInstitutionView extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _NoInstitutionView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.corporate_fare_outlined,
              size: 56,
              color: PETROL_DARK,
            ),
            const SizedBox(height: 14),
            const Text(
              'This account is not linked to a hospital yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make sure the logged-in account has institutionId in users/{uid}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: PETROL_DARK,
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}