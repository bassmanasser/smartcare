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
  int _currentIndex = 0;

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
        if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      final userDoc = await _firestore.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final institutionId = (userData['institutionId'] ?? '').toString();

      Map<String, dynamic>? hospitalData;
      if (institutionId.isNotEmpty) {
        final hospitalDoc =
            await _firestore.collection('institutions').doc(institutionId).get();
        hospitalData = hospitalDoc.data();
      }

      if (!mounted) return;

      setState(() {
        _userData = userData;
        _institutionId = institutionId;
        _hospitalData = hospitalData;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load hospital dashboard: $e')),
      );
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
        .get();

    return snapshot.docs.where((doc) {
      final data = doc.data();
      final severity = (data['severity'] ?? '').toString().toLowerCase();
      final priority = (data['priority'] ?? '').toString().toLowerCase();
      final status = (data['status'] ?? '').toString().toLowerCase();

      return status != 'closed' &&
          (severity == 'emergency' ||
              severity == 'high' ||
              priority == 'emergency' ||
              priority == 'high');
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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) {
      _loadData();
      if (mounted) setState(() {});
    });
  }

  String get _hospitalName {
    return (_hospitalData?['name'] ??
            _hospitalData?['hospitalName'] ??
            _userData?['institutionName'] ??
            'Hospital')
        .toString();
  }

  String get _hospitalCity {
    return (_hospitalData?['city'] ??
            _hospitalData?['hospitalCity'] ??
            'Unknown city')
        .toString();
  }

  String get _adminName {
    return (_userData?['name'] ?? _userData?['fullName'] ?? 'Admin').toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      _buildHomeTab(),
      _buildServicesTab(),
      _buildProfileTab(),
      _buildSettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(_hospitalName),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) {
          setState(() => _currentIndex = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services_rounded),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business_rounded),
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

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _HospitalOverviewCard(
            hospitalName: _hospitalName,
            institutionId: _institutionId,
            city: _hospitalCity,
            adminName: _adminName,
          ),
          const SizedBox(height: 16),
          const _SectionTitle(
            title: 'Overview',
            subtitle: 'Quick summary of your hospital today',
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<int>>(
            future: Future.wait([
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
                childAspectRatio: 1.18,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _ModernStatCard(
                    title: 'Doctors',
                    value: values[0].toString(),
                    icon: Icons.badge_outlined,
                  ),
                  _ModernStatCard(
                    title: 'Nurses',
                    value: values[1].toString(),
                    icon: Icons.local_hospital_outlined,
                  ),
                  _ModernStatCard(
                    title: 'Patients Today',
                    value: values[2].toString(),
                    icon: Icons.groups_outlined,
                  ),
                  _ModernStatCard(
                    title: 'Pending Approvals',
                    value: values[3].toString(),
                    icon: Icons.approval_outlined,
                  ),
                  _ModernStatCard(
                    title: 'Emergency Cases',
                    value: values[4].toString(),
                    icon: Icons.warning_amber_rounded,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const _SectionTitle(
            title: 'Latest Alerts',
            subtitle: 'Recent notifications and patient alerts',
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
            future: _loadRecentAlerts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data ?? [];

              if (docs.isEmpty) {
                return const _EmptyStateCard(
                  icon: Icons.notifications_none_rounded,
                  title: 'No alerts yet',
                  subtitle: 'Everything looks stable for now.',
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final title =
                      (data['title'] ?? data['type'] ?? 'Alert').toString();
                  final subtitle =
                      (data['message'] ?? data['description'] ?? '-').toString();
                  final patient =
                      (data['patientName'] ?? data['patientId'] ?? '').toString();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.10),
                        ),
                        child: Icon(
                          Icons.notifications_active_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          patient.isEmpty ? subtitle : '$patient\n$subtitle',
                        ),
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
    );
  }

  Widget _buildServicesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(
          title: 'Services',
          subtitle: 'Hospital operations and management tools',
        ),
        const SizedBox(height: 12),
        _ServiceCard(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Admit Patient',
          subtitle: 'Register and admit a new patient to the institution.',
          onTap: () => _push(
            AdmitPatientScreen(
              institutionId: _institutionId,
              institutionName: _hospitalName,
            ),
          ),
        ),
        _ServiceCard(
          icon: Icons.approval_rounded,
          title: 'Staff Approvals',
          subtitle: 'Review and approve pending doctors and nurses requests.',
          onTap: () => _push(
            StaffApprovalScreen(institutionId: _institutionId),
          ),
        ),
        _ServiceCard(
          icon: Icons.account_tree_outlined,
          title: 'Departments',
          subtitle: 'Manage hospital departments and institutional structure.',
          onTap: () => _push(
            DepartmentManagementScreen(institutionId: _institutionId),
          ),
        ),
        _ServiceCard(
          icon: Icons.emergency_rounded,
          title: 'Emergency Queue',
          subtitle: 'Track urgent patients and active emergency cases.',
          onTap: () => _push(const EmergencyQueueScreen()),
        ),
        _ServiceCard(
          icon: Icons.space_dashboard_outlined,
          title: 'Dispatch Dashboard',
          subtitle: 'Monitor smart medical dispatching and case flow.',
          onTap: () => _push(
            DispatchDashboardScreen(institutionId: _institutionId),
          ),
        ),
        _ServiceCard(
          icon: Icons.badge_outlined,
          title: 'Doctors List',
          subtitle: 'View all doctors linked to this hospital.',
          onTap: () => _push(
            HospitalPeopleListScreen(
              institutionId: _institutionId,
              title: 'Doctors',
              roleFilter: 'doctor',
            ),
          ),
        ),
        _ServiceCard(
          icon: Icons.health_and_safety_outlined,
          title: 'Nurses List',
          subtitle: 'View all nurses linked to this hospital.',
          onTap: () => _push(
            HospitalPeopleListScreen(
              institutionId: _institutionId,
              title: 'Nurses',
              roleFilter: 'nurse',
            ),
          ),
        ),
        _ServiceCard(
          icon: Icons.groups_2_outlined,
          title: 'Patients Today',
          subtitle: 'See all patients who arrived today.',
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
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HospitalOverviewCard(
          hospitalName: _hospitalName,
          institutionId: _institutionId,
          city: _hospitalCity,
          adminName: _adminName,
          compact: true,
        ),
        const SizedBox(height: 16),
        const _SectionTitle(
          title: 'Hospital Profile',
          subtitle: 'Basic information and institutional identity',
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ProfileInfoRow(label: 'Hospital Name', value: _hospitalName),
                _ProfileInfoRow(
                  label: 'Hospital ID',
                  value: _institutionId.isEmpty ? '-' : _institutionId,
                ),
                _ProfileInfoRow(label: 'City', value: _hospitalCity),
                _ProfileInfoRow(label: 'Admin Name', value: _adminName),
                _ProfileInfoRow(
                  label: 'Email',
                  value: (_userData?['email'] ?? _auth.currentUser?.email ?? '-')
                      .toString(),
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => _push(const HospitalProfileScreen()),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Open Full Hospital Profile'),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(
          title: 'Settings',
          subtitle: 'Manage dashboard actions and account options',
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Refresh data'),
                subtitle: const Text('Reload hospital information and counters'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _loadData,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.business_rounded),
                title: const Text('Hospital profile'),
                subtitle: const Text('Open hospital profile and institution details'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _push(const HospitalProfileScreen()),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Logout'),
                subtitle: const Text('Sign out from the hospital dashboard'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _signOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HospitalOverviewCard extends StatelessWidget {
  final String hospitalName;
  final String institutionId;
  final String city;
  final String adminName;
  final bool compact;

  const _HospitalOverviewCard({
    required this.hospitalName,
    required this.institutionId,
    required this.city,
    required this.adminName,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(compact ? 18 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.95),
            colorScheme.primaryContainer.withOpacity(0.90),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 58 : 64,
            height: compact ? 58 : 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospitalName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 20 : 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _HeaderMetaText(
                  label: 'Hospital ID',
                  value: institutionId.isEmpty ? '-' : institutionId,
                ),
                _HeaderMetaText(label: 'City', value: city),
                _HeaderMetaText(label: 'Admin', value: adminName),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetaText extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderMetaText({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Colors.white.withOpacity(0.92),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.70),
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: colorScheme.primary.withOpacity(0.10),
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.78),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colorScheme.primary.withOpacity(0.10),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
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
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.70),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
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
            Icon(icon, size: 42),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}