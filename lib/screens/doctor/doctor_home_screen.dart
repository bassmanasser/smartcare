import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dispatch_decision.dart';
import '../../models/doctor.dart';
import '../../models/patient.dart';
import '../../models/risk_assessment.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../auth/welcome_screen.dart';
import 'assigned_cases_screen.dart';
import 'doctor_patients_screen.dart';
import 'doctor_requests_screen.dart';
import 'doctor_scan_patient_screen.dart';
import 'patient_detail_for_doctor_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorHomeScreen({super.key, required this.doctor});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  int _selectedTab = 0;

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  String get _doctorName => widget.doctor.name.toString();
  String get _doctorSpecialty => widget.doctor.specialty.toString().isEmpty
      ? 'General'
      : widget.doctor.specialty.toString();

  String get _doctorScanId {
    final value = widget.doctor.doctorId.toString();
    if (value.isNotEmpty) return value;
    return widget.doctor.id.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final List<Patient> allPatients = app.patients
            .map((item) => Patient.fromJson(item))
            .where((p) => p.doctorId == widget.doctor.id)
            .toList();

        final queue = buildDoctorQueueData(allPatients, app);
        final emergencyCases = queue
            .where((e) => e.urgency == 'emergency')
            .toList();
        final urgentCases = queue.where((e) => e.urgency == 'urgent').toList();

        final tabs = [
          _DoctorOverviewTab(
            doctor: widget.doctor,
            app: app,
            queue: queue,
            emergencyCases: emergencyCases,
            urgentCases: urgentCases,
            allPatients: allPatients,
            doctorScanId: _doctorScanId,
          ),
          DoctorPatientsScreen(doctor: widget.doctor, queue: queue),
          _DoctorProfileTab(doctor: widget.doctor),
          _DoctorSettingsTab(
            doctor: widget.doctor,
            doctorScanId: _doctorScanId,
            onLogout: () => _logout(context),
          ),
        ];

        return Scaffold(
          backgroundColor: const Color(0xffF6F8FB),
          body: tabs[_selectedTab],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (i) => setState(() => _selectedTab = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Patients',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DoctorOverviewTab extends StatelessWidget {
  final Doctor doctor;
  final AppState app;
  final List<DoctorQueueItem> queue;
  final List<DoctorQueueItem> emergencyCases;
  final List<DoctorQueueItem> urgentCases;
  final List<Patient> allPatients;
  final String doctorScanId;

  const _DoctorOverviewTab({
    required this.doctor,
    required this.app,
    required this.queue,
    required this.emergencyCases,
    required this.urgentCases,
    required this.allPatients,
    required this.doctorScanId,
  });

  @override
  Widget build(BuildContext context) {
    final doctorName = doctor.name.toString();
    final specialty = doctor.specialty.toString().isEmpty
        ? 'General'
        : doctor.specialty.toString();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.delayed(const Duration(milliseconds: 250));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _DoctorHeaderCard(
              doctorName: doctorName,
              specialty: specialty,
              queueCount: queue.length,
              emergencyCount: emergencyCases.length,
            ),
            const SizedBox(height: 16),
            _InstitutionStatusCard(doctor: doctor),
            const SizedBox(height: 16),
            _DoctorStatsGrid(
              totalPatients: allPatients.length,
              emergencyCount: emergencyCases.length,
              urgentCount: urgentCases.length,
              alertsCount: app.alerts.length,
            ),
            const SizedBox(height: 20),
            const _SectionTitle(
              title: 'Clinical Work',
              subtitle: 'Main doctor tools in a cleaner professional layout',
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.assignment_outlined,
              title: 'Assigned Cases',
              subtitle: 'Review active and priority patient cases',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        AssignedCasesScreen(doctor: doctor, queue: queue),
                  ),
                );
              },
            ),
            _ActionTile(
              icon: Icons.description_outlined,
              title: 'Requests & Notes',
              subtitle: 'Track doctor requests and pending actions',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorRequestsScreen(
                      doctor: doctor,
                      doctorId: doctor.id,
                    ),
                  ),
                );
              },
            ),
            _ActionTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan Patient QR',
              subtitle: 'Link a patient to your doctor account',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorScanPatientScreen(
                      doctorId: doctorScanId,
                      doctorName: doctorName,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const _SectionTitle(
              title: 'Critical Queue',
              subtitle: 'Emergency and urgent cases that need quick attention',
            ),
            const SizedBox(height: 12),
            if (emergencyCases.isEmpty && urgentCases.isEmpty)
              const _EmptyStateCard(
                icon: Icons.local_hospital_outlined,
                title: 'No critical cases',
                subtitle: 'Emergency and urgent cases will appear here.',
              )
            else ...[
              ...emergencyCases.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CompactPriorityCard(item: item),
                ),
              ),
              ...urgentCases.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CompactPriorityCard(item: item),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DoctorProfileTab extends StatelessWidget {
  final Doctor doctor;

  const _DoctorProfileTab({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(doctor.id.toString())
              .snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() ?? {};
            final doctorName = doctor.name.toString();
            final specialty = doctor.specialty.toString().isEmpty
                ? 'General'
                : doctor.specialty.toString();

            final institutionName =
                (data['institutionName'] ?? 'Not assigned yet').toString();
            final departmentName =
                (data['departmentName'] ?? data['department'] ?? 'General')
                    .toString();
            final medicalRole = (data['medicalRole'] ?? 'Doctor').toString();
            final approvalStatus = (data['approvalStatus'] ?? 'pending')
                .toString();
            final employeeId = (data['employeeId'] ?? '--').toString();
            final licenseNumber = (data['licenseNumber'] ?? '--').toString();
            final phone = (data['phone'] ?? '--').toString();
            final email =
                (data['email'] ??
                        FirebaseAuth.instance.currentUser?.email ??
                        '--')
                    .toString();
            final institutionId = (data['institutionId'] ?? '--').toString();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _DoctorHeaderCard(
                  doctorName: doctorName,
                  specialty: specialty,
                  queueCount: 0,
                  emergencyCount: 0,
                  compact: true,
                ),
                const SizedBox(height: 16),
                const _SectionTitle(
                  title: 'Doctor Profile',
                  subtitle: 'Identity, hospital data, and registration details',
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _ProfileInfoRow(label: 'Full Name', value: doctorName),
                        _ProfileInfoRow(
                          label: 'Medical Role',
                          value: medicalRole,
                        ),
                        _ProfileInfoRow(label: 'Specialty', value: specialty),
                        _ProfileInfoRow(
                          label: 'Department',
                          value: departmentName,
                        ),
                        _ProfileInfoRow(
                          label: 'Hospital',
                          value: institutionName,
                        ),
                        _ProfileInfoRow(
                          label: 'Hospital ID',
                          value: institutionId,
                        ),
                        _ProfileInfoRow(
                          label: 'Employee ID',
                          value: employeeId,
                        ),
                        _ProfileInfoRow(
                          label: 'License Number',
                          value: licenseNumber,
                        ),
                        _ProfileInfoRow(
                          label: 'Approval Status',
                          value: approvalStatus,
                        ),
                        _ProfileInfoRow(label: 'Phone', value: phone),
                        _ProfileInfoRow(
                          label: 'Email',
                          value: email,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DoctorSettingsTab extends StatelessWidget {
  final Doctor doctor;
  final String doctorScanId;
  final VoidCallback onLogout;

  const _DoctorSettingsTab({
    required this.doctor,
    required this.doctorScanId,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final doctorName = doctor.name.toString();
    final specialty = doctor.specialty.toString().isEmpty
        ? 'General'
        : doctor.specialty.toString();

    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DoctorHeaderCard(
              doctorName: doctorName,
              specialty: specialty,
              queueCount: 0,
              emergencyCount: 0,
              compact: true,
            ),
            const SizedBox(height: 16),
            const _SectionTitle(
              title: 'Settings',
              subtitle: 'Doctor account options and system access',
            ),
            const SizedBox(height: 12),
            const _SettingTile(
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: 'Doctor screens now use clearer professional English',
            ),
            _SettingTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'Scan Patient QR',
              subtitle: 'Link a patient by scanning their QR code',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorScanPatientScreen(
                      doctorId: doctorScanId,
                      doctorName: doctorName,
                    ),
                  ),
                );
              },
            ),
            _SettingTile(
              icon: Icons.description_outlined,
              title: 'Requests',
              subtitle: 'Open doctor requests and follow-ups',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorRequestsScreen(
                      doctor: doctor,
                      doctorId: doctor.id,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorHeaderCard extends StatelessWidget {
  final String doctorName;
  final String specialty;
  final int queueCount;
  final int emergencyCount;
  final bool compact;

  const _DoctorHeaderCard({
    required this.doctorName,
    required this.specialty,
    required this.queueCount,
    required this.emergencyCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [PETROL_DARK, PETROL],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 58 : 64,
            height: compact ? 58 : 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.medical_services_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctorName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 20 : 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  specialty,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Assigned cases: $queueCount  •  Emergency: $emergencyCount',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstitutionStatusCard extends StatelessWidget {
  final Doctor doctor;

  const _InstitutionStatusCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(doctor.id.toString())
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final institutionName = (data['institutionName'] ?? 'Not assigned yet')
            .toString();
        final departmentName =
            (data['departmentName'] ?? data['department'] ?? 'General')
                .toString();
        final medicalRole = (data['medicalRole'] ?? 'Medical Staff').toString();
        final approvalStatus = (data['approvalStatus'] ?? 'pending').toString();
        final employeeId = (data['employeeId'] ?? '--').toString();

        return Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  title: 'Institution Status',
                  subtitle: 'Doctor role and hospital registration summary',
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: 'Hospital', value: institutionName),
                    _InfoChip(label: 'Department', value: departmentName),
                    _InfoChip(label: 'Role', value: medicalRole),
                    _InfoChip(label: 'Staff ID', value: employeeId),
                    _InfoChip(label: 'Approval', value: approvalStatus),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DoctorStatsGrid extends StatelessWidget {
  final int totalPatients;
  final int emergencyCount;
  final int urgentCount;
  final int alertsCount;

  const _DoctorStatsGrid({
    required this.totalPatients,
    required this.emergencyCount,
    required this.urgentCount,
    required this.alertsCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Patients',
                value: '$totalPatients',
                color: Colors.blue,
                icon: Icons.groups_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: 'Emergency',
                value: '$emergencyCount',
                color: Colors.red,
                icon: Icons.emergency_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Urgent',
                value: '$urgentCount',
                color: Colors.orange,
                icon: Icons.priority_high_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                title: 'Alerts',
                value: '$alertsCount',
                color: Colors.purple,
                icon: Icons.notifications_active_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: PETROL.withValues(alpha: 0.12),
          child: Icon(icon, color: PETROL_DARK),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
      ),
    );
  }
}

class _CompactPriorityCard extends StatelessWidget {
  final DoctorQueueItem item;

  const _CompactPriorityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = urgencyColor(item.urgency);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailForDoctorScreen(patient: item.patient),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(Icons.local_hospital_rounded, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${item.name} • ${pretty(item.urgency)} • ${pretty(item.specialty)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: PETROL.withValues(alpha: 0.12),
          child: Icon(icon, color: PETROL_DARK),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: onTap != null
            ? const Icon(Icons.arrow_forward_ios_rounded, size: 18)
            : null,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: PETROL.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: PETROL.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: PETROL,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            pretty(value),
            style: const TextStyle(
              color: PETROL_DARK,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: PETROL_DARK,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _ProfileInfoRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
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
        if (!isLast) ...[
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Icon(icon, size: 42, color: PETROL_DARK),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class DoctorQueueItem {
  final Patient patient;
  final String name;
  final String riskLevel;
  final String urgency;
  final String specialty;
  final String action;
  final String explanation;
  final int alertCount;
  final int sortValue;

  const DoctorQueueItem({
    required this.patient,
    required this.name,
    required this.riskLevel,
    required this.urgency,
    required this.specialty,
    required this.action,
    required this.explanation,
    required this.alertCount,
    required this.sortValue,
  });
}

List<DoctorQueueItem> buildDoctorQueueData(
  List<Patient> patients,
  AppState app,
) {
  final items = <DoctorQueueItem>[];

  for (final p in patients) {
    final riskLevel = app.currentAssessment?.riskLevel.key ?? 'normal';
    final urgency = app.currentDispatch?.urgency.key ?? 'routine';
    final specialty = app.currentDispatch?.specialty ?? 'general';
    final action = app.currentDispatch?.action.key ?? 'self_care';
    final explanation =
        app.currentDispatch?.explanation ??
        'No dispatch recommendation available yet.';

    items.add(
      DoctorQueueItem(
        patient: p,
        name: p.name,
        riskLevel: riskLevel,
        urgency: urgency,
        specialty: specialty,
        action: action,
        explanation: explanation,
        alertCount: app.alerts.length,
        sortValue: urgencySortValue(urgency),
      ),
    );
  }

  items.sort((a, b) => b.sortValue.compareTo(a.sortValue));
  return items;
}

int urgencySortValue(String urgency) {
  switch (urgency) {
    case 'emergency':
      return 4;
    case 'urgent':
      return 3;
    case 'priority':
      return 2;
    case 'routine':
    default:
      return 1;
  }
}

Color urgencyColor(String urgency) {
  switch (urgency) {
    case 'emergency':
      return Colors.red;
    case 'urgent':
      return Colors.deepOrange;
    case 'priority':
      return Colors.orange;
    case 'routine':
    default:
      return Colors.green;
  }
}

String pretty(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
      .join(' ');
}
