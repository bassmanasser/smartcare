import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';

class HospitalPeopleListScreen extends StatefulWidget {
  final String institutionId;
  final String title;
  final String roleFilter;
  final bool onlyToday;

  const HospitalPeopleListScreen({
    super.key,
    required this.institutionId,
    required this.title,
    required this.roleFilter,
    this.onlyToday = false,
  });

  @override
  State<HospitalPeopleListScreen> createState() =>
      _HospitalPeopleListScreenState();
}

class _HospitalPeopleListScreenState extends State<HospitalPeopleListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('institutionId', isEqualTo: widget.institutionId)
        .where('role', isEqualTo: widget.roleFilter);

    if (widget.onlyToday) {
      query = query.where('arrivalDayKey', isEqualTo: _todayKey());
    }

    return query;
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchText.trim().isEmpty) return true;

    final q = _searchText.trim().toLowerCase();

    final values = [
      (data['name'] ?? '').toString().toLowerCase(),
      (data['email'] ?? '').toString().toLowerCase(),
      (data['phone'] ?? '').toString().toLowerCase(),
      (data['departmentName'] ?? '').toString().toLowerCase(),
      (data['employeeId'] ?? '').toString().toLowerCase(),
      (data['patientId'] ?? '').toString().toLowerCase(),
      (data['medicalRole'] ?? '').toString().toLowerCase(),
      (data['staffRole'] ?? '').toString().toLowerCase(),
    ];

    return values.any((v) => v.contains(q));
  }

  Future<void> _removeFromHospital(String uid) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Remove from hospital'),
            content: const Text(
              'Are you sure you want to unlink this account from the hospital?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;

    if (!ok) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'institutionId': FieldValue.delete(),
        'institutionName': FieldValue.delete(),
        'institutionCity': FieldValue.delete(),
        'departmentName': FieldValue.delete(),
        'approvalStatus': 'removed',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from hospital')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Color _roleColor() {
    switch (widget.roleFilter) {
      case 'doctor':
        return PETROL_DARK;
      case 'nurse':
        return Colors.teal;
      case 'staff':
        return ACCENT_ORANGE;
      case 'patient':
        return Colors.deepPurple;
      default:
        return PETROL;
    }
  }

  IconData _roleIcon() {
    switch (widget.roleFilter) {
      case 'doctor':
        return Icons.medical_services_rounded;
      case 'nurse':
        return Icons.health_and_safety_rounded;
      case 'staff':
        return Icons.badge_rounded;
      case 'patient':
        return Icons.personal_injury_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  String _subtitleFor(Map<String, dynamic> data) {
    if (widget.roleFilter == 'doctor') {
      final role = (data['medicalRole'] ?? 'Doctor').toString();
      final dep = (data['departmentName'] ?? 'No department').toString();
      final empId = (data['employeeId'] ?? '--').toString();
      return '$role • $dep • ID: $empId';
    }

    if (widget.roleFilter == 'nurse') {
      final dep = (data['departmentName'] ?? 'No department').toString();
      final empId = (data['employeeId'] ?? '--').toString();
      return 'Nurse • $dep • ID: $empId';
    }

    if (widget.roleFilter == 'staff') {
      final role = (data['staffRole'] ?? 'Staff').toString();
      final dep = (data['departmentName'] ?? 'No department').toString();
      final empId = (data['employeeId'] ?? '--').toString();
      return '$role • $dep • ID: $empId';
    }

    final patientId = (data['patientId'] ?? '--').toString();
    final triage = (data['triageLevel'] ?? 'General').toString();
    return 'Patient ID: $patientId • $triage';
  }

  Widget _topHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_roleColor(), _roleColor().withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white24,
            child: Icon(_roleIcon(), color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hospital ID: ${widget.institutionId}',
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

  Widget _searchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => setState(() => _searchText = v),
      decoration: InputDecoration(
        hintText: 'Search by name, email, ID, department...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchText.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchText = '');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _personCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = (data['name'] ?? 'Unknown').toString();
    final email = (data['email'] ?? '--').toString();
    final phone = (data['phone'] ?? '--').toString();
    final approval = (data['approvalStatus'] ?? 'approved').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _roleColor().withOpacity(0.12),
              child: Icon(_roleIcon(), color: _roleColor()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleFor(data),
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _smallChip(
                        icon: Icons.approval_rounded,
                        text: approval,
                        color: approval == 'approved'
                            ? Colors.green
                            : Colors.orange,
                      ),
                      _smallChip(
                        icon: Icons.business_rounded,
                        text: widget.institutionId,
                        color: PETROL_DARK,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.roleFilter != 'patient')
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'remove') {
                    _removeFromHospital(doc.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove from hospital'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _smallChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(_roleIcon(), size: 42, color: _roleColor()),
          const SizedBox(height: 10),
          Text(
            'No ${widget.title.toLowerCase()} found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hospital ID: ${widget.institutionId}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        backgroundColor: LIGHT_BG,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _buildQuery().snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = (snapshot.data?.docs ?? [])
                .where((doc) => _matchesSearch(doc.data()))
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              children: [
                _topHeader(),
                const SizedBox(height: 14),
                _searchBox(),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    'Total: ${docs.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (docs.isEmpty)
                  _emptyView()
                else
                  ...docs.map(_personCard),
              ],
            );
          },
        ),
      ),
    );
  }
}