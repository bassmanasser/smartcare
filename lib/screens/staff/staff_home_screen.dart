import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import 'staff_patients_screen.dart';
import 'staff_scan_patient_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  bool _loading = true;
  int _selectedTab = 0;

  Map<String, dynamic> _userData = {};
  String _staffName = 'Staff';
  String _institutionName = 'Hospital';
  String _institutionId = '';
  String _departmentName = 'General';
  String _medicalRole = 'Staff';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      if (!mounted) return;
      setState(() {
        _userData = data;
        _staffName = (data['name'] ?? data['fullName'] ?? 'Staff').toString();
        _institutionName =
            (data['institutionName'] ?? 'Hospital').toString();
        _institutionId = (data['institutionId'] ?? '').toString();
        _departmentName =
            (data['departmentName'] ?? data['department'] ?? 'General')
                .toString();
        _medicalRole = (data['medicalRole'] ?? 'Staff').toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load staff data: $e')),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<int> _countAssignedPatients() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 0;

    final snap = await FirebaseFirestore.instance
        .collection('care_links')
        .where('linkedUserId', isEqualTo: uid)
        .where('linkedUserRole', isEqualTo: 'staff')
        .where('status', isEqualTo: 'approved')
        .get();

    return snap.docs.length;
  }

  Future<int> _countTodayPatients() async {
    if (_institutionId.isEmpty) return 0;

    final now = DateTime.now();
    final dayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('institutionId', isEqualTo: _institutionId)
        .where('role', isEqualTo: 'patient')
        .where('arrivalDayKey', isEqualTo: dayKey)
        .get();

    return snap.docs.length;
  }

  Future<int> _countAlerts() async {
    if (_institutionId.isEmpty) return 0;

    final snap = await FirebaseFirestore.instance
        .collection('alerts')
        .where('institutionId', isEqualTo: _institutionId)
        .get();

    return snap.docs.length;
  }

  Future<int> _countOpenCases() async {
    if (_institutionId.isEmpty) return 0;

    final snap = await FirebaseFirestore.instance
        .collection('dispatch_cases')
        .where('institutionId', isEqualTo: _institutionId)
        .where('status', whereIn: ['waiting', 'in_progress'])
        .get();

    return snap.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xffF6F8FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final staffId =
        (_userData['uid'] ?? FirebaseAuth.instance.currentUser?.uid ?? '')
            .toString();

    final pages = [
      _buildHomeTab(staffId),
      StaffPatientsScreen(staffId: staffId),
      _buildProfileTab(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF6F8FB),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (i) {
          setState(() => _selectedTab = i);
        },
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
  }

  Widget _buildHomeTab(String staffId) {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _StaffHeaderCard(
            staffName: _staffName,
            institutionName: _institutionName,
            departmentName: _departmentName,
            medicalRole: _medicalRole,
          ),
          const SizedBox(height: 16),
          const _SectionTitle(
            title: 'Overview',
            subtitle: 'Professional staff dashboard summary',
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<int>>(
            future: Future.wait([
              _countAssignedPatients(),
              _countTodayPatients(),
              _countAlerts(),
              _countOpenCases(),
            ]),
            builder: (context, snapshot) {
              final values = snapshot.data ?? [0, 0, 0, 0];
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.18,
                children: [
                  _StatCard(
                    title: 'Assigned Patients',
                    value: values[0].toString(),
                    icon: Icons.groups_rounded,
                    color: Colors.blue,
                  ),
                  _StatCard(
                    title: 'Patients Today',
                    value: values[1].toString(),
                    icon: Icons.today_rounded,
                    color: Colors.teal,
                  ),
                  _StatCard(
                    title: 'Alerts',
                    value: values[2].toString(),
                    icon: Icons.notifications_active_rounded,
                    color: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Open Cases',
                    value: values[3].toString(),
                    icon: Icons.local_hospital_rounded,
                    color: Colors.red,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            title: 'Staff Work',
            subtitle: 'Main staff tools in a clean professional layout',
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan Patient QR',
            subtitle: 'Link a patient by scanning QR or entering patient ID',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StaffScanPatientScreen(
                    staffId: staffId,
                    staffName: _staffName,
                  ),
                ),
              );
            },
          ),
          _ActionTile(
            icon: Icons.groups_outlined,
            title: 'My Patients',
            subtitle: 'Open patient list assigned to this staff member',
            onTap: () {
              setState(() => _selectedTab = 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final email =
        (_userData['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '--')
            .toString();
    final phone = (_userData['phone'] ?? '--').toString();
    final employeeId = (_userData['employeeId'] ?? '--').toString();
    final approvalStatus = (_userData['approvalStatus'] ?? 'pending').toString();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StaffHeaderCard(
          staffName: _staffName,
          institutionName: _institutionName,
          departmentName: _departmentName,
          medicalRole: _medicalRole,
          compact: true,
        ),
        const SizedBox(height: 16),
        const _SectionTitle(
          title: 'Staff Profile',
          subtitle: 'Identity, department, and hospital registration details',
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ProfileInfoRow(label: 'Full Name', value: _staffName),
                _ProfileInfoRow(label: 'Medical Role', value: _medicalRole),
                _ProfileInfoRow(label: 'Department', value: _departmentName),
                _ProfileInfoRow(label: 'Hospital', value: _institutionName),
                _ProfileInfoRow(
                  label: 'Hospital ID',
                  value: _institutionId.isEmpty ? '--' : _institutionId,
                ),
                _ProfileInfoRow(label: 'Employee ID', value: employeeId),
                _ProfileInfoRow(label: 'Approval Status', value: approvalStatus),
                _ProfileInfoRow(label: 'Phone', value: phone),
                _ProfileInfoRow(label: 'Email', value: email, isLast: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StaffHeaderCard(
          staffName: _staffName,
          institutionName: _institutionName,
          departmentName: _departmentName,
          medicalRole: _medicalRole,
          compact: true,
        ),
        const SizedBox(height: 16),
        const _SectionTitle(
          title: 'Settings',
          subtitle: 'Staff account options',
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.language_rounded,
          title: 'Language',
          subtitle: 'Staff pages now use clearer professional English',
          onTap: () {},
        ),
        _ActionTile(
          icon: Icons.refresh_rounded,
          title: 'Refresh Data',
          subtitle: 'Reload staff dashboard data',
          onTap: _loadUserData,
        ),
        _ActionTile(
          icon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: 'Sign out from staff account',
          onTap: _logout,
        ),
      ],
    );
  }
}

class _StaffHeaderCard extends StatelessWidget {
  final String staffName;
  final String institutionName;
  final String departmentName;
  final String medicalRole;
  final bool compact;

  const _StaffHeaderCard({
    required this.staffName,
    required this.institutionName,
    required this.departmentName,
    required this.medicalRole,
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
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.badge_rounded,
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
                  staffName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 20 : 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$institutionName • $departmentName',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  medicalRole,
                  style: const TextStyle(
                    color: Colors.white70,
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
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

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
        Text(
          subtitle,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
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
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
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
          backgroundColor: PETROL.withOpacity(0.12),
          child: Icon(icon, color: PETROL_DARK),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
      ),
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