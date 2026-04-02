import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dispatch_decision.dart';
import '../../models/doctor.dart';
import '../../models/risk_assessment.dart';
import '../../providers/app_state.dart';
import '../../utils/constants.dart';
import '../auth/welcome_screen.dart';
import 'doctor_appointments_screen.dart';
import 'doctor_scan_patient_screen.dart';
import 'doctor_stats_screen.dart';
import 'patient_detail_for_doctor_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  final Doctor doctor;

  const DoctorHomeScreen({
    super.key,
    required this.doctor,
  });

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
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final patientsMap = app.patients ?? {};
        final allPatients = patientsMap.values
            .where((p) => p.doctorId == widget.doctor.id)
            .toList();

        final queue = _buildQueueData(allPatients, app);

        final emergencyCases =
            queue.where((e) => e.urgency == 'emergency').toList();
        final urgentCases = queue.where((e) => e.urgency == 'urgent').toList();

        final tabs = [
          _DoctorOverviewTab(
            doctor: widget.doctor,
            app: app,
            queue: queue,
            emergencyCases: emergencyCases,
            urgentCases: urgentCases,
            allPatients: allPatients,
          ),
          _DispatchQueueTab(queue: queue),
          _PatientsTab(queue: queue),
          _DoctorSettingsTab(
            doctor: widget.doctor,
            onLogout: () => _logout(context),
          ),
        ];

        return Scaffold(
          backgroundColor: const Color(0xffF6F8FB),
          body: tabs[_selectedTab],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedTab,
            onTap: (i) => setState(() => _selectedTab = i),
            selectedItemColor: PETROL,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Overview',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.local_hospital_rounded),
                label: 'Queue',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups_rounded),
                label: 'Patients',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
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
  final List<_DoctorQueueItem> queue;
  final List<_DoctorQueueItem> emergencyCases;
  final List<_DoctorQueueItem> urgentCases;
  final List allPatients;

  const _DoctorOverviewTab({
    required this.doctor,
    required this.app,
    required this.queue,
    required this.emergencyCases,
    required this.urgentCases,
    required this.allPatients,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DoctorHeader(
                doctor: doctor,
                queueCount: queue.length,
                emergencyCount: emergencyCases.length,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _InstitutionStatusCard(doctor: doctor),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StatsGrid(
                  totalPatients: allPatients.length,
                  emergencyCount: emergencyCases.length,
                  urgentCount: urgentCases.length,
                  alertsCount: app.alerts.length,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _QuickActionsGrid(
                  doctor: doctor,
                  allPatients: allPatients,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PrioritySection(
                  title: 'Critical & Urgent Queue',
                  items: [
                    ...emergencyCases,
                    ...urgentCases,
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _DispatchQueueTab extends StatelessWidget {
  final List<_DoctorQueueItem> queue;

  const _DispatchQueueTab({required this.queue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      appBar: AppBar(
        title: const Text('Dispatch Queue'),
        centerTitle: true,
        backgroundColor: PETROL_DARK,
        automaticallyImplyLeading: false,
      ),
      body: queue.isEmpty
          ? const Center(
              child: Text(
                'No patient cases in queue yet.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = queue[index];
                return _QueueCaseCard(item: item);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: queue.length,
            ),
    );
  }
}

class _PatientsTab extends StatelessWidget {
  final List<_DoctorQueueItem> queue;

  const _PatientsTab({required this.queue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      appBar: AppBar(
        title: const Text('My Patients'),
        centerTitle: true,
        backgroundColor: PETROL_DARK,
        automaticallyImplyLeading: false,
      ),
      body: queue.isEmpty
          ? const Center(
              child: Text('No linked patients yet.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final item = queue[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PatientListCard(item: item),
                );
              },
            ),
    );
  }
}

class _DoctorSettingsTab extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onLogout;

  const _DoctorSettingsTab({
    required this.doctor,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      appBar: AppBar(
        title: const Text('Doctor Settings'),
        centerTitle: true,
        backgroundColor: PETROL_DARK,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DoctorInfoCard(doctor: doctor),
          const SizedBox(height: 14),
          _InstitutionInfoCard(doctor: doctor),
          const SizedBox(height: 14),
          _SettingTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan Patient QR',
            subtitle: 'Link a patient by scanning their QR code',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DoctorScanPatientScreen(
                    doctorId: (doctor.doctorId ?? doctor.id).toString(),
                    doctorName: (doctor.name ?? 'Doctor').toString(),
                  ),
                ),
              );
            },
          ),
          _SettingTile(
            icon: Icons.verified_rounded,
            title: 'Verification Status',
            subtitle:
                (doctor.isApproved == true) ? 'Verified' : 'Pending approval',
          ),
          _SettingTile(
            icon: Icons.medical_services_rounded,
            title: 'Specialty',
            subtitle: (doctor.specialty ?? 'General').toString(),
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
    );
  }
}

class _DoctorHeader extends StatelessWidget {
  final Doctor doctor;
  final int queueCount;
  final int emergencyCount;

  const _DoctorHeader({
    required this.doctor,
    required this.queueCount,
    required this.emergencyCount,
  });

  @override
  Widget build(BuildContext context) {
    final specialty = (doctor.specialty ?? 'General').toString();
    final doctorName = (doctor.name ?? 'Doctor').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      decoration: const BoxDecoration(
        color: PETROL_DARK,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person_rounded, size: 34, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: emergencyCount > 0
                      ? Colors.red.withOpacity(0.18)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        emergencyCount > 0 ? Colors.redAccent : Colors.white24,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Emergency',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$emergencyCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Scan patient QR to link new patient and add to queue.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
          .doc((doctor.id).toString())
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final institutionName =
            (data['institutionName'] ?? 'Not assigned yet').toString();
        final departmentName =
            (data['departmentName'] ?? 'General').toString();
        final medicalRole =
            (data['medicalRole'] ?? 'Medical Staff').toString();
        final approvalStatus =
            (data['approvalStatus'] ?? 'pending').toString();
        final employeeId = (data['employeeId'] ?? '--').toString();
        final availabilityStatus =
            (data['availabilityStatus'] ?? 'available').toString();

        final statusColor = _approvalColor(approvalStatus);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Institution Status',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: PETROL_DARK,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    label: 'Institution',
                    value: institutionName,
                    color: Colors.blue,
                  ),
                  _InfoChip(
                    label: 'Department',
                    value: departmentName,
                    color: Colors.teal,
                  ),
                  _InfoChip(
                    label: 'Role',
                    value: medicalRole,
                    color: Colors.indigo,
                  ),
                  _InfoChip(
                    label: 'Staff ID',
                    value: employeeId,
                    color: Colors.deepPurple,
                  ),
                  _InfoChip(
                    label: 'Approval',
                    value: approvalStatus,
                    color: statusColor,
                  ),
                  _InfoChip(
                    label: 'Availability',
                    value: availabilityStatus,
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InstitutionInfoCard extends StatelessWidget {
  final Doctor doctor;

  const _InstitutionInfoCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc((doctor.id).toString())
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final institutionName =
            (data['institutionName'] ?? 'Not assigned yet').toString();
        final institutionCode =
            (data['institutionCode'] ?? '--').toString();
        final departmentName =
            (data['departmentName'] ?? 'General').toString();
        final employeeId = (data['employeeId'] ?? '--').toString();
        final licenseNumber =
            (data['licenseNumber'] ?? '--').toString();

        return _SectionCard(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 34,
                backgroundColor: Color(0xffE8F3F3),
                child:
                    Icon(Icons.local_hospital, size: 34, color: PETROL_DARK),
              ),
              const SizedBox(height: 12),
              Text(
                institutionName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Department: $departmentName',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffF6F8FB),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _simpleInfoRow('Institution Code', institutionCode),
                    const SizedBox(height: 8),
                    _simpleInfoRow('Employee ID', employeeId),
                    const SizedBox(height: 8),
                    _simpleInfoRow('License Number', licenseNumber),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _simpleInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: PETROL_DARK,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int totalPatients;
  final int emergencyCount;
  final int urgentCount;
  final int alertsCount;

  const _StatsGrid({
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

class _QuickActionsGrid extends StatelessWidget {
  final Doctor doctor;
  final List allPatients;

  const _QuickActionsGrid({
    required this.doctor,
    required this.allPatients,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionItem(
        title: 'Scan Patient',
        icon: Icons.qr_code_scanner_rounded,
        color: Colors.teal,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorScanPatientScreen(
                doctorId: (doctor.doctorId ?? doctor.id).toString(),
                doctorName: (doctor.name ?? 'Doctor').toString(),
              ),
            ),
          );
        },
      ),
      _QuickActionItem(
        title: 'Statistics',
        icon: Icons.bar_chart_rounded,
        color: Colors.indigo,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorStatsScreen(
                myPatients: allPatients,
                fee: doctor.fee ?? 0.0,
                totalPatients: allPatients.length,
              ),
            ),
          );
        },
      ),
      _QuickActionItem(
        title: 'Appointments',
        icon: Icons.calendar_month_rounded,
        color: Colors.blue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DoctorAppointmentsScreen(myPatients: allPatients),
            ),
          );
        },
      ),
      _QuickActionItem(
        title: 'Patients',
        icon: Icons.people_alt_rounded,
        color: Colors.red,
        onTap: () {},
      ),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: PETROL_DARK,
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: actions.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final item = actions[index];
              return GestureDetector(
                onTap: item.onTap,
                child: Container(
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: item.color, size: 28),
                      const SizedBox(height: 10),
                      Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: PETROL_DARK,
                        ),
                      ),
                    ],
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

class _PrioritySection extends StatelessWidget {
  final String title;
  final List<_DoctorQueueItem> items;

  const _PrioritySection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: PETROL_DARK,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text('No critical cases right now.')
          else
            ...items.take(5).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CompactPriorityCard(item: item),
                  ),
                ),
        ],
      ),
    );
  }
}

class _QueueCaseCard extends StatelessWidget {
  final _DoctorQueueItem item;

  const _QueueCaseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _urgencyColor(item.urgency);

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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: urgencyColor.withOpacity(0.28)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: urgencyColor.withOpacity(0.12),
                  child: Icon(Icons.person_rounded, color: urgencyColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Specialty: ${_pretty(item.specialty)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                _UrgencyBadge(urgency: item.urgency),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Risk',
                    value: _pretty(item.riskLevel),
                  ),
                ),
                Expanded(
                  child: _MiniMetric(
                    label: 'Action',
                    value: _pretty(item.action),
                  ),
                ),
                Expanded(
                  child: _MiniMetric(
                    label: 'Alerts',
                    value: '${item.alertCount}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffF6F8FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                item.explanation,
                style: const TextStyle(height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientListCard extends StatelessWidget {
  final _DoctorQueueItem item;

  const _PatientListCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PatientDetailForDoctorScreen(patient: item.patient),
          ),
        );
      },
      child: _SectionCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: PETROL.withOpacity(0.12),
              child: const Icon(Icons.person_rounded, color: PETROL_DARK),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Risk: ${_pretty(item.riskLevel)} • Specialty: ${_pretty(item.specialty)}',
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

class _CompactPriorityCard extends StatelessWidget {
  final _DoctorQueueItem item;

  const _CompactPriorityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(item.urgency);

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
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(Icons.local_hospital_rounded, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${item.name} • ${_pretty(item.urgency)} • ${_pretty(item.specialty)}',
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

class _DoctorInfoCard extends StatelessWidget {
  final Doctor doctor;

  const _DoctorInfoCard({
    required this.doctor,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xffE8F3F3),
            child: Icon(Icons.person_rounded, size: 36, color: PETROL_DARK),
          ),
          const SizedBox(height: 12),
          Text(
            (doctor.name ?? 'Doctor').toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            (doctor.specialty ?? 'General').toString(),
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xffF6F8FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Use Scan Patient QR to link new patients',
              style: TextStyle(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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
          backgroundColor: PETROL.withOpacity(0.12),
          child: Icon(icon, color: PETROL_DARK),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing:
            onTap != null ? const Icon(Icons.arrow_forward_ios_rounded, size: 18) : null,
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _MiniMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: PETROL_DARK,
          ),
        ),
      ],
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  final String urgency;

  const _UrgencyBadge({required this.urgency});

  @override
  Widget build(BuildContext context) {
    final color = _urgencyColor(urgency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        _pretty(urgency),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
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
    return _SectionCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _pretty(value),
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

class _QuickActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _QuickActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DoctorQueueItem {
  final dynamic patient;
  final String name;
  final String riskLevel;
  final String urgency;
  final String specialty;
  final String action;
  final String explanation;
  final int alertCount;
  final int sortValue;

  const _DoctorQueueItem({
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

List<_DoctorQueueItem> _buildQueueData(List patients, AppState app) {
  final items = <_DoctorQueueItem>[];

  for (final p in patients) {
    final riskLevel = app.currentAssessment?.riskLevel.key ?? 'normal';
    final urgency = app.currentDispatch?.urgency.key ?? 'routine';
    final specialty = app.currentDispatch?.specialty ?? 'general';
    final action = app.currentDispatch?.action.key ?? 'self_care';
    final explanation = app.currentDispatch?.explanation ??
        'No dispatch recommendation available yet.';

    items.add(
      _DoctorQueueItem(
        patient: p,
        name: (p.name ?? 'Patient').toString(),
        riskLevel: riskLevel,
        urgency: urgency,
        specialty: specialty,
        action: action,
        explanation: explanation,
        alertCount: app.alerts.length,
        sortValue: _urgencySortValue(urgency),
      ),
    );
  }

  items.sort((a, b) => b.sortValue.compareTo(a.sortValue));
  return items;
}

int _urgencySortValue(String urgency) {
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

Color _urgencyColor(String urgency) {
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

Color _approvalColor(String status) {
  switch (status) {
    case 'approved':
      return Colors.green;
    case 'rejected':
      return Colors.red;
    default:
      return Colors.orange;
  }
}

String _pretty(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1)}')
      .join(' ');
}