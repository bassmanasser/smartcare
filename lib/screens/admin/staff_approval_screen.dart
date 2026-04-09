import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StaffApprovalScreen extends StatefulWidget {
  final String institutionId;

  const StaffApprovalScreen({
    super.key,
    required this.institutionId,
  });

  @override
  State<StaffApprovalScreen> createState() => _StaffApprovalScreenState();
}

class _StaffApprovalScreenState extends State<StaffApprovalScreen> {
  bool _processing = false;
  String _searchText = '';
  String _roleFilter = 'all';

  Stream<QuerySnapshot<Map<String, dynamic>>> _requestsStream() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('staff_requests')
        .where('institutionId', isEqualTo: widget.institutionId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true);

    if (_roleFilter != 'all') {
      query = query.where('role', isEqualTo: _roleFilter);
    }

    return query.snapshots();
  }

  Future<void> _approve(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    if (_processing) return;

    setState(() => _processing = true);

    final data = doc.data();
    final uid = (data['uid'] ?? data['userId'] ?? '').toString();

    try {
      await FirebaseFirestore.instance.collection('staff_requests').doc(doc.id).set({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (uid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'approvalStatus': 'approved',
          'institutionId': widget.institutionId,
          'institutionName': (data['institutionName'] ?? '').toString(),
          'department': data['department'],
          'role': data['role'],
          'employeeId': data['employeeId'],
          'licenseNumber': data['licenseNumber'],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Staff member approved successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _reject(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    if (_processing) return;

    setState(() => _processing = true);

    try {
      await FirebaseFirestore.instance.collection('staff_requests').doc(doc.id).set({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final uid = (doc.data()['uid'] ?? doc.data()['userId'] ?? '').toString();

      if (uid.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'approvalStatus': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request rejected')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reject failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchText.trim().isEmpty) return true;

    final q = _searchText.trim().toLowerCase();
    final values = [
      data['name'],
      data['fullName'],
      data['email'],
      data['role'],
      data['department'],
      data['employeeId'],
      data['licenseNumber'],
      data['institutionName'],
    ];

    return values.any((v) => v.toString().toLowerCase().contains(q));
  }

  IconData _iconForRole(String role) {
    switch (role) {
      case 'doctor':
        return Icons.badge_outlined;
      case 'nurse':
        return Icons.local_hospital_outlined;
      default:
        return Icons.person_outline_rounded;
    }
  }

  Color _badgeColor(BuildContext context, String role) {
    final primary = Theme.of(context).colorScheme.primary;
    if (role == 'doctor') return primary;
    if (role == 'nurse') return Colors.teal;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Approvals'),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            padding: const EdgeInsets.all(18),
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
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.approval_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pending Staff Requests',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Review doctors and nurses before adding them to your hospital.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchText = v),
              decoration: InputDecoration(
                hintText: 'Search by name, role, department, email...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _FilterChipButton(
                    label: 'All',
                    selected: _roleFilter == 'all',
                    onTap: () => setState(() => _roleFilter = 'all'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterChipButton(
                    label: 'Doctors',
                    selected: _roleFilter == 'doctor',
                    onTap: () => setState(() => _roleFilter = 'doctor'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterChipButton(
                    label: 'Nurses',
                    selected: _roleFilter == 'nurse',
                    onTap: () => setState(() => _roleFilter = 'nurse'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _requestsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Something went wrong: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((d) => _matchesSearch(d.data())).toList();

                if (filtered.isEmpty) {
                  return const _ApprovalEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();

                    final name =
                        (data['name'] ?? data['fullName'] ?? 'Unknown').toString();
                    final role = (data['role'] ?? '-').toString();
                    final department = (data['department'] ?? '').toString();
                    final email = (data['email'] ?? '').toString();
                    final employeeId = (data['employeeId'] ?? '').toString();
                    final licenseNumber =
                        (data['licenseNumber'] ?? '').toString();

                    return Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: colorScheme.primary.withOpacity(0.10),
                                  ),
                                  child: Icon(
                                    _iconForRole(role),
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _RoleBadge(
                                            label: role,
                                            color: _badgeColor(context, role),
                                          ),
                                          if (department.isNotEmpty)
                                            _SoftChip(label: department),
                                          if (employeeId.isNotEmpty)
                                            _SoftChip(label: 'ID: $employeeId'),
                                        ],
                                      ),
                                      if (email.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          email,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color
                                                ?.withOpacity(0.72),
                                          ),
                                        ),
                                      ],
                                      if (licenseNumber.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'License: $licenseNumber',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color
                                                ?.withOpacity(0.72),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        _processing ? null : () => _reject(doc),
                                    icon: const Icon(Icons.close_rounded),
                                    label: const Text('Reject'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed:
                                        _processing ? null : () => _approve(doc),
                                    icon: const Icon(Icons.check_rounded),
                                    label: const Text('Approve'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
          : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  final String label;

  const _SoftChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _ApprovalEmptyState extends StatelessWidget {
  const _ApprovalEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.approval_outlined, size: 42),
              const SizedBox(height: 12),
              const Text(
                'No pending requests',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All staff requests are already processed.',
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
      ),
    );
  }
}