import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmergencyQueueScreen extends StatefulWidget {
  const EmergencyQueueScreen({super.key});

  @override
  State<EmergencyQueueScreen> createState() => _EmergencyQueueScreenState();
}

class _EmergencyQueueScreenState extends State<EmergencyQueueScreen> {
  String _filter = 'all';

  bool _matchesFilter(Map<String, dynamic> data) {
    if (_filter == 'all') return true;
    final severity = (data['severity'] ?? '').toString().toLowerCase();
    final priority = (data['priority'] ?? '').toString().toLowerCase();
    return severity == _filter || priority == _filter;
  }

  Color _severityColor(String value) {
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

  Future<void> _updateStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance.collection('dispatch_cases').doc(docId).set({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Case marked as $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update case: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Queue'),
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
                    Icons.emergency_rounded,
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
                        'Emergency Queue',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Monitor urgent and emergency patient cases',
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
            child: Row(
              children: [
                Expanded(
                  child: _QueueFilter(
                    label: 'All',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QueueFilter(
                    label: 'Emergency',
                    selected: _filter == 'emergency',
                    onTap: () => setState(() => _filter = 'emergency'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QueueFilter(
                    label: 'Urgent',
                    selected: _filter == 'urgent',
                    onTap: () => setState(() => _filter = 'urgent'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('dispatch_cases')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Something went wrong: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                final filtered = docs.where((d) {
                  final data = d.data();
                  final status = (data['status'] ?? '').toString().toLowerCase();
                  return status != 'closed' && _matchesFilter(data);
                }).toList();

                if (filtered.isEmpty) {
                  return const _EmergencyEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();

                    final patientName =
                        (data['patientName'] ?? 'Unknown Patient').toString();
                    final priority =
                        (data['priority'] ?? data['severity'] ?? 'normal')
                            .toString();
                    final status = (data['status'] ?? 'waiting').toString();
                    final notes = (data['notes'] ?? '').toString();
                    final institution =
                        (data['institutionName'] ?? '').toString();

                    final severityColor = _severityColor(priority);

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
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: severityColor.withOpacity(0.12),
                                  ),
                                  child: Icon(
                                    Icons.warning_amber_rounded,
                                    color: severityColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patientName,
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
                                          _EmergencyBadge(
                                            label: priority,
                                            color: severityColor,
                                          ),
                                          _EmergencyBadge(
                                            label: status,
                                            color: Colors.blueGrey,
                                          ),
                                        ],
                                      ),
                                      if (institution.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          institution,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color
                                                ?.withOpacity(0.72),
                                          ),
                                        ),
                                      ],
                                      if (notes.isNotEmpty) ...[
                                        const SizedBox(height: 6),
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
                                  child: OutlinedButton(
                                    onPressed: () =>
                                        _updateStatus(doc.id, 'in_progress'),
                                    child: const Text('In Progress'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () =>
                                        _updateStatus(doc.id, 'closed'),
                                    child: const Text('Close Case'),
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

class _QueueFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QueueFilter({
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
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
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

class _EmergencyBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _EmergencyBadge({
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

class _EmergencyEmptyState extends StatelessWidget {
  const _EmergencyEmptyState();

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
              const Icon(Icons.emergency_outlined, size: 42),
              const SizedBox(height: 12),
              const Text(
                'No active emergency cases',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Everything looks stable right now.',
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