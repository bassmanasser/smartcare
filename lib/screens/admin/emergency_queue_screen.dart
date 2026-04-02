import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class EmergencyQueueScreen extends StatelessWidget {
  const EmergencyQueueScreen({super.key});

  Color _priorityColor(String value) {
    switch (value) {
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.deepOrange;
      case 'high':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Future<void> _assignDepartment(
    BuildContext context,
    String uid,
    String department,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'assignedDepartment': department,
        'workflowStage': 'department_assigned',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assigned to $department')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment failed: $e')),
      );
    }
  }

  Future<void> _markEscalated(BuildContext context, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'workflowStage': 'icu_escalation',
        'queuePriority': 'emergency',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Case escalated to ICU flow')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Escalation failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: const Text('Emergency Queue'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'patient')
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          final queueDocs = docs.where((doc) {
            final data = doc.data();
            final q = (data['queuePriority'] ?? 'routine').toString();
            return q == 'emergency' || q == 'urgent' || q == 'high';
          }).toList();

          queueDocs.sort((a, b) {
            final pa = (a.data()['queuePriority'] ?? '').toString();
            final pb = (b.data()['queuePriority'] ?? '').toString();

            int score(String p) {
              switch (p) {
                case 'emergency':
                  return 4;
                case 'urgent':
                  return 3;
                case 'high':
                  return 2;
                default:
                  return 1;
              }
            }

            return score(pb).compareTo(score(pa));
          });

          if (queueDocs.isEmpty) {
            return const Center(
              child: Text('No urgent or emergency cases right now'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: queueDocs.length,
            itemBuilder: (context, index) {
              final doc = queueDocs[index];
              final data = doc.data();

              final name = (data['name'] ?? 'Unknown').toString();
              final priority = (data['queuePriority'] ?? 'routine').toString();
              final institution =
                  (data['assignedInstitutionCode'] ?? '--').toString();
              final stage = (data['workflowStage'] ?? 'patient_intake').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _priorityColor(priority).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              _priorityColor(priority).withOpacity(0.12),
                          child: Icon(
                            Icons.person,
                            color: _priorityColor(priority),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _priorityColor(priority).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            priority.toUpperCase(),
                            style: TextStyle(
                              color: _priorityColor(priority),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _row('Institution', institution),
                    const SizedBox(height: 8),
                    _row('Stage', stage),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              _assignDepartment(context, doc.id, 'Cardiology'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Cardiology'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _assignDepartment(context, doc.id, 'Pulmonology'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Pulmonology'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              _assignDepartment(context, doc.id, 'Endocrinology'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Endocrinology'),
                        ),
                        ElevatedButton(
                          onPressed: () => _markEscalated(context, doc.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Escalate ICU'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: PETROL_DARK,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}