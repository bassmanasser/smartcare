import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class AssignedCasesScreen extends StatelessWidget {
  final String doctorUid;

  const AssignedCasesScreen({
    super.key,
    required this.doctorUid,
  });

  Future<void> _updateCase(
    BuildContext context,
    String patientUid,
    Map<String, dynamic> data,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(patientUid)
          .set(data, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Case updated')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Color _statusColor(String stage) {
    switch (stage) {
      case 'icu_escalation':
        return Colors.red;
      case 'under_review':
        return Colors.orange;
      case 'closed':
        return Colors.green;
      default:
        return PETROL;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: const Text('Assigned Cases'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'patient')
            .where('assignedDoctorUid', isEqualTo: doctorUid)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No assigned cases yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();

              final name = (data['name'] ?? 'Unknown').toString();
              final stage = (data['workflowStage'] ?? 'assigned').toString();
              final department =
                  (data['assignedDepartment'] ?? '--').toString();
              final priority = (data['queuePriority'] ?? 'routine').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              _statusColor(stage).withOpacity(0.12),
                          child: Icon(Icons.person, color: _statusColor(stage)),
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
                        Text(
                          priority.toUpperCase(),
                          style: TextStyle(
                            color: _statusColor(stage),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _row('Department', department),
                    const SizedBox(height: 8),
                    _row('Stage', stage),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () => _updateCase(context, doc.id, {
                            'workflowStage': 'under_review',
                            'updatedAt': FieldValue.serverTimestamp(),
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Accept'),
                        ),
                        ElevatedButton(
                          onPressed: () => _updateCase(context, doc.id, {
                            'workflowStage': 'transferred',
                            'updatedAt': FieldValue.serverTimestamp(),
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Transfer'),
                        ),
                        ElevatedButton(
                          onPressed: () => _updateCase(context, doc.id, {
                            'workflowStage': 'icu_escalation',
                            'queuePriority': 'emergency',
                            'updatedAt': FieldValue.serverTimestamp(),
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Escalate'),
                        ),
                        ElevatedButton(
                          onPressed: () => _updateCase(context, doc.id, {
                            'workflowStage': 'closed',
                            'updatedAt': FieldValue.serverTimestamp(),
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Close'),
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
          width: 95,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: PETROL_DARK,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}