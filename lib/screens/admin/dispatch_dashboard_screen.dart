import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DispatchDashboardScreen extends StatefulWidget {
  final String institutionId;

  const DispatchDashboardScreen({
    super.key,
    required this.institutionId,
  });

  @override
  State<DispatchDashboardScreen> createState() =>
      _DispatchDashboardScreenState();
}

class _DispatchDashboardScreenState extends State<DispatchDashboardScreen> {
  Future<int> _countCasesByStatus(String status) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('dispatch_cases')
        .where('institutionId', isEqualTo: widget.institutionId)
        .where('status', isEqualTo: status)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _countCasesByPriority(String priority) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('dispatch_cases')
        .where('institutionId', isEqualTo: widget.institutionId)
        .where('priority', isEqualTo: priority)
        .get();
    return snapshot.docs.length;
  }

  Future<void> _assignDepartment(String docId, String department) async {
    try {
      await FirebaseFirestore.instance.collection('dispatch_cases').doc(docId).set({
        'assignedDepartment': department,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department assigned successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign department: $e')),
      );
    }
  }

  Future<List<String>> _loadDepartments() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('departments')
        .where('institutionId', isEqualTo: widget.institutionId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((e) => (e.data()['name'] ?? '').toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }

  void _showDepartmentPicker(String caseId) async {
    final departments = await _loadDepartments();
    if (!mounted) return;

    if (departments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active departments available')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: departments.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final dept = departments[index];
            return ListTile(
              leading: const Icon(Icons.apartment_rounded),
              title: Text(dept),
              onTap: () {
                Navigator.of(context).pop();
                _assignDepartment(caseId, dept);
              },
            );
          },
        );
      },
    );
  }

  Color _priorityColor(String value) {
    switch (value.toLowerCase()) {
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'normal':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
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
                    Icons.space_dashboard_outlined,
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
                        'Smart Dispatch Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Track routing, priority, and department assignment',
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
          const SizedBox(height: 18),
          FutureBuilder<List<int>>(
            future: Future.wait([
              _countCasesByStatus('waiting'),
              _countCasesByStatus('in_progress'),
              _countCasesByPriority('urgent'),
              _countCasesByPriority('emergency'),
            ]),
            builder: (context, snapshot) {
              final values = snapshot.data ?? [0, 0, 0, 0];
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.18,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _DispatchStatCard(
                    title: 'Waiting',
                    value: values[0].toString(),
                    icon: Icons.hourglass_bottom_rounded,
                  ),
                  _DispatchStatCard(
                    title: 'In Progress',
                    value: values[1].toString(),
                    icon: Icons.sync_rounded,
                  ),
                  _DispatchStatCard(
                    title: 'Urgent',
                    value: values[2].toString(),
                    icon: Icons.priority_high_rounded,
                  ),
                  _DispatchStatCard(
                    title: 'Emergency',
                    value: values[3].toString(),
                    icon: Icons.warning_amber_rounded,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          const _DispatchSectionTitle(
            title: 'Live Dispatch Cases',
            subtitle: 'Recent institution cases ready for routing',
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('dispatch_cases')
                .where('institutionId', isEqualTo: widget.institutionId)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Something went wrong: ${snapshot.error}'),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return const _DispatchEmptyState();
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data();
                  final patient =
                      (data['patientName'] ?? 'Unknown Patient').toString();
                  final priority =
                      (data['priority'] ?? data['severity'] ?? 'normal')
                          .toString();
                  final status = (data['status'] ?? 'waiting').toString();
                  final notes = (data['notes'] ?? '').toString();
                  final department =
                      (data['assignedDepartment'] ?? '').toString();

                  final pColor = _priorityColor(priority);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: pColor.withOpacity(0.12),
                                ),
                                child: Icon(
                                  Icons.local_shipping_outlined,
                                  color: pColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _DispatchChip(
                                          label: priority,
                                          color: pColor,
                                        ),
                                        _DispatchChip(
                                          label: status,
                                          color: Colors.blueGrey,
                                        ),
                                        if (department.isNotEmpty)
                                          _DispatchChip(
                                            label: department,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                      ],
                                    ),
                                    if (notes.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        notes,
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
                                  onPressed: () => _showDepartmentPicker(doc.id),
                                  icon: const Icon(Icons.apartment_rounded),
                                  label: const Text('Assign Department'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('dispatch_cases')
                                        .doc(doc.id)
                                        .set({
                                      'status': 'in_progress',
                                      'updatedAt': FieldValue.serverTimestamp(),
                                    }, SetOptions(merge: true));
                                  },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Start'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}

class _DispatchStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _DispatchStatCard({
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

class _DispatchSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DispatchSectionTitle({
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

class _DispatchChip extends StatelessWidget {
  final String label;
  final Color color;

  const _DispatchChip({
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

class _DispatchEmptyState extends StatelessWidget {
  const _DispatchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.space_dashboard_outlined, size: 42),
            const SizedBox(height: 12),
            const Text(
              'No dispatch cases yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'New admitted cases will appear here for department routing.',
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