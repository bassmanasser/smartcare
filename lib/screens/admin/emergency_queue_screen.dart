import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmergencyQueueScreen extends StatelessWidget {
  const EmergencyQueueScreen({super.key});

  Color _priorityColor(String value) {
    switch (value.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Queue')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('dispatch_cases')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final data = doc.data();
            final priority = (data['priority'] ?? data['severity'] ?? 'normal')
                .toString()
                .toLowerCase();
            final status = (data['status'] ?? 'waiting').toString().toLowerCase();
            return ['high', 'urgent', 'emergency'].contains(priority) &&
                status != 'closed';
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('No emergency cases right now'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final priority =
                  (data['priority'] ?? data['severity'] ?? 'normal').toString();
              final color = _priorityColor(priority);
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(Icons.warning_amber_rounded, color: color),
                  ),
                  title: Text(
                    (data['patientName'] ?? 'Unknown Patient').toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Priority: $priority'),
                        Text('Status: ${(data['status'] ?? 'waiting').toString()}'),
                        Text(
                          'Institution: ${(data['institutionName'] ?? data['institutionId'] ?? '-').toString()}',
                        ),
                        if ((data['notes'] ?? '').toString().trim().isNotEmpty)
                          Text('Notes: ${(data['notes'] ?? '').toString()}'),
                      ],
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      priority.toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
