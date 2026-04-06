import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../../utils/localization.dart';
import 'hospital_people_list_screen.dart';
import 'hospital_profile_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String _staffSearch = '';
  String _patientSearch = '';
  String _staffRoleFilter = 'all';
  String _approvalRoleFilter = 'all';

  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<Map<String, dynamic>?> _loadAdminData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return userDoc.data();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  void _copyText(String text, String successMsg) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(successMsg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadAdminData(),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final adminData = adminSnapshot.data ?? {};
        final institutionId = (adminData['institutionId'] ?? '').toString();
        final institutionName = (adminData['institutionName'] ?? '').toString();
        final adminName = (adminData['name'] ?? '').toString();
        final institutionAddress =
            (adminData['institutionAddress'] ?? '').toString();
        final institutionCity = (adminData['institutionCity'] ?? '').toString();

        if (institutionId.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Hospital Admin'),
              backgroundColor: PETROL_DARK,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text('No hospital linked to this admin account'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: LIGHT_BG,
          appBar: AppBar(
            backgroundColor: PETROL_DARK,
            foregroundColor: Colors.white,
            title: Text('${tr.translate('institution')} Dashboard'),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HospitalProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.local_hospital),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  final appState =
                      Provider.of<AppState>(context, listen: false);

                  if (value == 'ar') {
                    appState.changeLanguage('ar');
                  } else if (value == 'en') {
                    appState.changeLanguage('en');
                  } else if (value == 'logout') {
                    await _logout();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'ar',
                    child: Text(tr.translate('arabic')),
                  ),
                  PopupMenuItem(
                    value: 'en',
                    child: Text(tr.translate('english')),
                  ),
                  PopupMenuItem(
                    value: 'logout',
                    child: Text(tr.translate('logout')),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HospitalHeaderCard(
                institutionName: institutionName,
                institutionId: institutionId,
                adminName: adminName,
                institutionAddress: institutionAddress,
                institutionCity: institutionCity,
                onCopyId: () => _copyText(
                  institutionId,
                  tr.translate('copied'),
                ),
                onOpenProfile: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HospitalProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _QuickActionsSection(
                institutionId: institutionId,
                onOpenProfile: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HospitalProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              _StatsGrid(
                institutionId: institutionId,
                todayKey: _todayKey(),
              ),
              const SizedBox(height: 18),
              _MiniAnalyticsSection(
                institutionId: institutionId,
                todayKey: _todayKey(),
              ),
              const SizedBox(height: 18),
              _DepartmentOverviewSection(
                institutionId: institutionId,
                todayKey: _todayKey(),
              ),
              const SizedBox(height: 18),
              _ShiftSummarySection(institutionId: institutionId),
              const SizedBox(height: 18),
              _AlertsSummarySection(
                institutionId: institutionId,
                todayKey: _todayKey(),
              ),
              const SizedBox(height: 18),
              _ApprovalCenterSection(
                institutionId: institutionId,
                roleFilter: _approvalRoleFilter,
                onRoleChanged: (value) {
                  setState(() => _approvalRoleFilter = value);
                },
              ),
              const SizedBox(height: 18),
              _StaffOverviewSection(
                institutionId: institutionId,
                search: _staffSearch,
                roleFilter: _staffRoleFilter,
                onSearchChanged: (v) {
                  setState(() => _staffSearch = v);
                },
                onRoleChanged: (v) {
                  setState(() => _staffRoleFilter = v);
                },
              ),
              const SizedBox(height: 18),
              _PatientsTodaySection(
                institutionId: institutionId,
                todayKey: _todayKey(),
                search: _patientSearch,
                onSearchChanged: (v) {
                  setState(() => _patientSearch = v);
                },
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}

class _HospitalHeaderCard extends StatelessWidget {
  final String institutionName;
  final String institutionId;
  final String adminName;
  final String institutionAddress;
  final String institutionCity;
  final VoidCallback onCopyId;
  final VoidCallback onOpenProfile;

  const _HospitalHeaderCard({
    required this.institutionName,
    required this.institutionId,
    required this.adminName,
    required this.institutionAddress,
    required this.institutionCity,
    required this.onCopyId,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PETROL_DARK,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            institutionName.isEmpty ? 'Hospital' : institutionName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            runSpacing: 8,
            spacing: 8,
            children: [
              _headerChip('ID: $institutionId'),
              _headerChip(
                institutionCity.isEmpty ? 'City not set' : institutionCity,
              ),
              _headerChip('Admin: ${adminName.isEmpty ? '-' : adminName}'),
              _headerChip('Status: Active'),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            institutionAddress.isEmpty ? '-' : institutionAddress,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: onCopyId,
                icon: const Icon(Icons.copy),
                label: const Text('Copy ID'),
              ),
              OutlinedButton.icon(
                onPressed: onOpenProfile,
                icon: const Icon(Icons.edit),
                label: const Text('Hospital Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12.5),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  final String institutionId;
  final VoidCallback onOpenProfile;

  const _QuickActionsSection({
    required this.institutionId,
    required this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quick Actions',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _ActionBtn(
            label: 'Hospital Profile',
            icon: Icons.local_hospital,
            onTap: onOpenProfile,
          ),
          _ActionBtn(
            label: 'All Doctors',
            icon: Icons.medical_services,
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
          _ActionBtn(
            label: 'All Nurses',
            icon: Icons.local_hospital,
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
          _ActionBtn(
            label: 'Today Patients',
            icon: Icons.groups,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HospitalPeopleListScreen(
                    institutionId: institutionId,
                    title: 'Patients Today',
                    roleFilter: 'patient',
                    onlyToday: true,
                  ),
                ),
              );
            },
          ),
          _ActionBtn(
            label: 'Pending Requests',
            icon: Icons.approval,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HospitalPeopleListScreen(
                    institutionId: institutionId,
                    title: 'Pending Requests',
                    roleFilter: 'pending_requests',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final String institutionId;
  final String todayKey;

  const _StatsGrid({
    required this.institutionId,
    required this.todayKey,
  });

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .snapshots();

    final requestsStream = FirebaseFirestore.instance
        .collection('staff_requests')
        .where('institutionId', isEqualTo: institutionId)
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, usersSnap) {
        final docs = usersSnap.data?.docs ?? [];

        int doctors = 0;
        int nurses = 0;
        int triage = 0;
        int support = 0;
        int todayPatients = 0;
        int activeCases = 0;
        int criticalToday = 0;
        int onDuty = 0;

        for (final doc in docs) {
          final data = doc.data();
          final role = (data['role'] ?? '').toString();
          final arrivalDayKey = (data['arrivalDayKey'] ?? '').toString();
          final patientStatus = (data['patientStatus'] ?? '').toString();
          final priorityLevel = (data['priorityLevel'] ?? '').toString();
          final dutyStatus = (data['dutyStatus'] ?? '').toString();

          if (role == 'doctor') doctors++;
          if (role == 'nurse') nurses++;
          if (role == 'triage_staff') triage++;
          if (role == 'support_staff') support++;
          if (dutyStatus == 'on_duty') onDuty++;

          if (role == 'patient' && arrivalDayKey == todayKey) {
            todayPatients++;
            if ([
              'Waiting',
              'In Triage',
              'Assigned',
              'Under Observation',
              'Emergency'
            ].contains(patientStatus)) {
              activeCases++;
            }
            if (priorityLevel == 'High' || priorityLevel == 'Critical') {
              criticalToday++;
            }
          }
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: requestsStream,
          builder: (context, reqSnap) {
            final pendingRequests = reqSnap.data?.docs.length ?? 0;

            return _SectionCard(
              title: 'Hospital Overview',
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.35,
                children: [
                  _StatCard(title: 'Doctors', value: '$doctors', icon: Icons.medical_services),
                  _StatCard(title: 'Nurses', value: '$nurses', icon: Icons.local_hospital),
                  _StatCard(title: 'Support Staff', value: '${triage + support}', icon: Icons.badge),
                  _StatCard(title: 'Patients Today', value: '$todayPatients', icon: Icons.groups),
                  _StatCard(title: 'Critical Today', value: '$criticalToday', icon: Icons.warning_amber_rounded),
                  _StatCard(title: 'Pending Requests', value: '$pendingRequests', icon: Icons.approval),
                  _StatCard(title: 'Active Cases', value: '$activeCases', icon: Icons.monitor_heart),
                  _StatCard(title: 'On Duty Staff', value: '$onDuty', icon: Icons.schedule),
                ],
              ),
            );
          },
        );
      },
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PETROL.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: PETROL_DARK,
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: PETROL_DARK,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _MiniAnalyticsSection extends StatelessWidget {
  final String institutionId;
  final String todayKey;

  const _MiniAnalyticsSection({
    required this.institutionId,
    required this.todayKey,
  });

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        final Map<String, int> patientDeptCount = {};
        final Map<String, int> alertTypeCount = {};
        int criticalCases = 0;

        for (final doc in docs) {
          final d = doc.data();
          final role = (d['role'] ?? '').toString();

          if (role == 'patient' &&
              (d['arrivalDayKey'] ?? '').toString() == todayKey) {
            final dept = (d['assignedDepartment'] ??
                    d['departmentName'] ??
                    'General')
                .toString();
            patientDeptCount[dept] = (patientDeptCount[dept] ?? 0) + 1;

            final priority = (d['priorityLevel'] ?? '').toString();
            if (priority == 'High' || priority == 'Critical') {
              criticalCases++;
            }

            final lastAlert = (d['lastAlertType'] ?? '').toString();
            if (lastAlert.isNotEmpty) {
              alertTypeCount[lastAlert] = (alertTypeCount[lastAlert] ?? 0) + 1;
            }
          }
        }

        String busiestDept = '-';
        int busiestDeptCount = 0;

        patientDeptCount.forEach((key, value) {
          if (value > busiestDeptCount) {
            busiestDept = key;
            busiestDeptCount = value;
          }
        });

        String highestAlertType = '-';
        int highestAlertCount = 0;

        alertTypeCount.forEach((key, value) {
          if (value > highestAlertCount) {
            highestAlertType = key;
            highestAlertCount = value;
          }
        });

        return _SectionCard(
          title: 'Mini Analytics',
          child: Column(
            children: [
              _AnalyticsTile(
                title: 'Busiest Department Today',
                value: busiestDept,
                subtitle: '$busiestDeptCount patients',
              ),
              const SizedBox(height: 10),
              _AnalyticsTile(
                title: 'Highest Alert Type',
                value: highestAlertType,
                subtitle: '$highestAlertCount alerts',
              ),
              const SizedBox(height: 10),
              _AnalyticsTile(
                title: 'Critical Load Today',
                value: '$criticalCases',
                subtitle: 'high / critical cases',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _AnalyticsTile({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LIGHT_BG,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: PETROL_DARK,
                  ),
                ),
                Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.insights, color: PETROL_DARK),
        ],
      ),
    );
  }
}

class _DepartmentOverviewSection extends StatelessWidget {
  final String institutionId;
  final String todayKey;

  const _DepartmentOverviewSection({
    required this.institutionId,
    required this.todayKey,
  });

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .snapshots();

    final departments = [
      'Cardiology',
      'Emergency',
      'ICU',
      'Internal Medicine',
      'Pediatrics',
      'General',
    ];

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        return _SectionCard(
          title: 'Departments Overview',
          child: Column(
            children: departments.map((dept) {
              int doctors = 0;
              int nurses = 0;
              int patientsToday = 0;

              for (final doc in docs) {
                final d = doc.data();
                final role = (d['role'] ?? '').toString();
                final departmentName = (d['departmentName'] ?? '').toString();
                final assignedDepartment =
                    (d['assignedDepartment'] ?? '').toString();
                final arrivalDayKey = (d['arrivalDayKey'] ?? '').toString();

                if (role == 'doctor' && departmentName == dept) doctors++;
                if (role == 'nurse' && departmentName == dept) nurses++;
                if (role == 'patient' &&
                    arrivalDayKey == todayKey &&
                    (assignedDepartment == dept || departmentName == dept)) {
                  patientsToday++;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: LIGHT_BG,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        dept,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: PETROL_DARK,
                        ),
                      ),
                    ),
                    _smallCount('D', doctors),
                    const SizedBox(width: 8),
                    _smallCount('N', nurses),
                    const SizedBox(width: 8),
                    _smallCount('P', patientsToday),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _smallCount(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text('$label: $count'),
    );
  }
}

class _ShiftSummarySection extends StatelessWidget {
  final String institutionId;

  const _ShiftSummarySection({required this.institutionId});

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        int morning = 0;
        int evening = 0;
        int night = 0;
        int onDuty = 0;
        int offDuty = 0;

        for (final doc in docs) {
          final d = doc.data();
          final role = (d['role'] ?? '').toString();

          if (![
            'doctor',
            'nurse',
            'triage_staff',
            'support_staff'
          ].contains(role)) {
            continue;
          }

          final shift = (d['shift'] ?? '').toString();
          final dutyStatus = (d['dutyStatus'] ?? '').toString();

          if (shift == 'Morning') morning++;
          if (shift == 'Evening') evening++;
          if (shift == 'Night') night++;

          if (dutyStatus == 'on_duty') {
            onDuty++;
          } else {
            offDuty++;
          }
        }

        return _SectionCard(
          title: 'Shift Summary',
          child: Row(
            children: [
              Expanded(child: _ShiftCard(title: 'Morning', count: morning)),
              const SizedBox(width: 10),
              Expanded(child: _ShiftCard(title: 'Evening', count: evening)),
              const SizedBox(width: 10),
              Expanded(child: _ShiftCard(title: 'Night', count: night)),
              const SizedBox(width: 10),
              Expanded(child: _ShiftCard(title: 'On Duty', count: onDuty)),
            ],
          ),
        );
      },
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final String title;
  final int count;

  const _ShiftCard({
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LIGHT_BG,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: PETROL_DARK,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _AlertsSummarySection extends StatelessWidget {
  final String institutionId;
  final String todayKey;

  const _AlertsSummarySection({
    required this.institutionId,
    required this.todayKey,
  });

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .where('role', isEqualTo: 'patient')
        .where('arrivalDayKey', isEqualTo: todayKey)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        int fallAlerts = 0;
        int lowSpo2Alerts = 0;
        int feverAlerts = 0;
        int abnormalHrAlerts = 0;

        for (final doc in docs) {
          final d = doc.data();
          if (d['fallAlert'] == true) fallAlerts++;
          if (d['lowSpo2Alert'] == true) lowSpo2Alerts++;
          if (d['feverAlert'] == true) feverAlerts++;
          if (d['abnormalHrAlert'] == true) abnormalHrAlerts++;
        }

        return _SectionCard(
          title: 'Alerts & Emergency Summary',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _AlertCard(title: 'Fall Alerts', value: fallAlerts)),
                  const SizedBox(width: 10),
                  Expanded(child: _AlertCard(title: 'Low SpO₂', value: lowSpo2Alerts)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _AlertCard(title: 'Fever Alerts', value: feverAlerts)),
                  const SizedBox(width: 10),
                  Expanded(child: _AlertCard(title: 'Abnormal HR', value: abnormalHrAlerts)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String title;
  final int value;

  const _AlertCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: LIGHT_BG,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: PETROL_DARK,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ApprovalCenterSection extends StatelessWidget {
  final String institutionId;
  final String roleFilter;
  final ValueChanged<String> onRoleChanged;

  const _ApprovalCenterSection({
    required this.institutionId,
    required this.roleFilter,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('staff_requests')
        .where('institutionId', isEqualTo: institutionId)
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        var docs = snapshot.data?.docs ?? [];

        if (roleFilter != 'all') {
          docs = docs.where((e) {
            return (e.data()['role'] ?? '').toString() == roleFilter;
          }).toList();
        }

        return _SectionCard(
          title: 'Approval Center',
          child: Column(
            children: [
              _RoleFilterBar(
                value: roleFilter,
                onChanged: onRoleChanged,
                includePatient: false,
              ),
              const SizedBox(height: 14),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Text('No pending requests'),
                ),
              ...docs.map((doc) {
                final data = doc.data();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LIGHT_BG,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: PETROL_DARK,
                            child: Icon(Icons.badge, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (data['name'] ?? '').toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: PETROL_DARK,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${data['role'] ?? '-'} • ${data['departmentName'] ?? '-'} • ${data['employeeId'] ?? '-'}',
                                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('staff_requests')
                                    .doc(doc.id)
                                    .set({
                                  'approvalStatus': 'rejected',
                                  'reviewedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));

                                final uid = (data['uid'] ?? '').toString();
                                if (uid.isNotEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .set({
                                    'approvalStatus': 'rejected',
                                  }, SetOptions(merge: true));
                                }
                              },
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('staff_requests')
                                    .doc(doc.id)
                                    .set({
                                  'approvalStatus': 'approved',
                                  'reviewedAt': FieldValue.serverTimestamp(),
                                }, SetOptions(merge: true));

                                final uid = (data['uid'] ?? '').toString();
                                if (uid.isNotEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .set({
                                    'approvalStatus': 'approved',
                                  }, SetOptions(merge: true));
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: PETROL_DARK,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _StaffOverviewSection extends StatelessWidget {
  final String institutionId;
  final String search;
  final String roleFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onRoleChanged;

  const _StaffOverviewSection({
    required this.institutionId,
    required this.search,
    required this.roleFilter,
    required this.onSearchChanged,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, snapshot) {
        var docs = snapshot.data?.docs ?? [];

        docs = docs.where((doc) {
          final d = doc.data();
          final role = (d['role'] ?? '').toString();
          return [
            'doctor',
            'nurse',
            'triage_staff',
            'support_staff'
          ].contains(role);
        }).toList();

        if (roleFilter != 'all') {
          docs = docs.where((doc) {
            return (doc.data()['role'] ?? '').toString() == roleFilter;
          }).toList();
        }

        if (search.trim().isNotEmpty) {
          docs = docs.where((doc) {
            final d = doc.data();
            final name = (d['name'] ?? '').toString().toLowerCase();
            final employeeId = (d['employeeId'] ?? '').toString().toLowerCase();
            final dept = (d['departmentName'] ?? '').toString().toLowerCase();
            final q = search.toLowerCase();
            return name.contains(q) ||
                employeeId.contains(q) ||
                dept.contains(q);
          }).toList();
        }

        docs.sort((a, b) {
          final aName = (a.data()['name'] ?? '').toString();
          final bName = (b.data()['name'] ?? '').toString();
          return aName.compareTo(bName);
        });

        return _SectionCard(
          title: 'Staff Overview',
          child: Column(
            children: [
              TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by name / employee ID / department',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: LIGHT_BG,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _RoleFilterBar(
                value: roleFilter,
                onChanged: onRoleChanged,
                includePatient: false,
              ),
              const SizedBox(height: 14),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No staff found'),
                ),
              ...docs.take(8).map((doc) {
                final d = doc.data();
                final status = (d['approvalStatus'] ?? '').toString();
                final shift = (d['shift'] ?? '-').toString();
                final dutyStatus = (d['dutyStatus'] ?? '-').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LIGHT_BG,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: PETROL_DARK,
                        child: Icon(
                          _roleIcon((d['role'] ?? '').toString()),
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (d['name'] ?? '').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: PETROL_DARK,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${d['role'] ?? '-'} • ${d['departmentName'] ?? '-'}',
                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${d['employeeId'] ?? '-'} • Shift: $shift • Duty: $dutyStatus',
                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      _statusChip(status),
                    ],
                  ),
                );
              }),
              if (docs.length > 8)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HospitalPeopleListScreen(
                            institutionId: institutionId,
                            title: 'All Staff',
                            roleFilter: roleFilter == 'all' ? '' : roleFilter,
                          ),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'doctor':
        return Icons.medical_services;
      case 'nurse':
        return Icons.local_hospital;
      case 'triage_staff':
        return Icons.route;
      default:
        return Icons.badge;
    }
  }

  Widget _statusChip(String status) {
    Color color = Colors.orange;
    if (status == 'approved') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        status.isEmpty ? '-' : status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PatientsTodaySection extends StatelessWidget {
  final String institutionId;
  final String todayKey;
  final String search;
  final ValueChanged<String> onSearchChanged;

  const _PatientsTodaySection({
    required this.institutionId,
    required this.todayKey,
    required this.search,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .where('institutionId', isEqualTo: institutionId)
        .where('role', isEqualTo: 'patient')
        .where('arrivalDayKey', isEqualTo: todayKey)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: usersStream,
      builder: (context, snapshot) {
        var docs = snapshot.data?.docs ?? [];

        if (search.trim().isNotEmpty) {
          docs = docs.where((doc) {
            final d = doc.data();
            final name = (d['name'] ?? '').toString().toLowerCase();
            final status = (d['patientStatus'] ?? '').toString().toLowerCase();
            final priority = (d['priorityLevel'] ?? '').toString().toLowerCase();
            final q = search.toLowerCase();
            return name.contains(q) || status.contains(q) || priority.contains(q);
          }).toList();
        }

        docs.sort((a, b) {
          final aTime = (a.data()['arrivalTimestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime = (b.data()['arrivalTimestamp'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          return bTime.compareTo(aTime);
        });

        return _SectionCard(
          title: 'Patients Today',
          child: Column(
            children: [
              TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search patient / status / priority',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: LIGHT_BG,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (docs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('No patients arrived today'),
                ),
              ...docs.take(8).map((doc) {
                final d = doc.data();
                final name = (d['name'] ?? '').toString();
                final patientStatus = (d['patientStatus'] ?? 'Waiting').toString();
                final priorityLevel = (d['priorityLevel'] ?? 'Normal').toString();
                final assignedDepartment =
                    (d['assignedDepartment'] ?? d['departmentName'] ?? '-')
                        .toString();
                final assignedDoctor =
                    (d['assignedDoctorName'] ?? '-').toString();
                final assignedNurse =
                    (d['assignedNurseName'] ?? '-').toString();
                final timestamp = d['arrivalTimestamp'] as Timestamp?;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LIGHT_BG,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: PETROL_DARK,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: PETROL_DARK,
                              ),
                            ),
                          ),
                          _priorityChip(priorityLevel),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _metaChip('Status: $patientStatus'),
                          _metaChip('Dept: $assignedDepartment'),
                          _metaChip('Doctor: $assignedDoctor'),
                          _metaChip('Nurse: $assignedNurse'),
                          _metaChip('Arrival: ${_formatTime(timestamp)}'),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              if (docs.length > 8)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HospitalPeopleListScreen(
                            institutionId: institutionId,
                            title: 'Patients Today',
                            roleFilter: 'patient',
                            onlyToday: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '-';
    final dt = ts.toDate();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Widget _priorityChip(String priority) {
    Color color = Colors.green;
    if (priority == 'Medium') color = Colors.orange;
    if (priority == 'High' || priority == 'Critical') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        priority,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _metaChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _RoleFilterBar extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final bool includePatient;

  const _RoleFilterBar({
    required this.value,
    required this.onChanged,
    this.includePatient = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      'all',
      'doctor',
      'nurse',
      'triage_staff',
      'support_staff',
      if (includePatient) 'patient',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final selected = value == item;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(item),
              selected: selected,
              onSelected: (_) => onChanged(item),
              selectedColor: PETROL_DARK.withOpacity(0.15),
              labelStyle: TextStyle(
                color: selected ? PETROL_DARK : Colors.black87,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PETROL.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: PETROL_DARK,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}