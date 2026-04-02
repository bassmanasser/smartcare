import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
        title: const Text('Institution Dashboard'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: db
            .collection('staff_requests')
            .where('approvalStatus', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionTitle('Pending Staff Approvals'),
              const SizedBox(height: 12),
              if (docs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No pending requests right now.'),
                  ),
                ),
              ...docs.map((doc) {
                final data = doc.data();
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: PETROL,
                      child: Icon(Icons.badge, color: Colors.white),
                    ),
                    title: Text(data['name'] ?? 'Unknown'),
                    subtitle: Text(
                      '${data['medicalRole'] ?? ''} • ${data['departmentName'] ?? ''}\n${data['institutionName'] ?? ''}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        await db.collection('staff_requests').doc(doc.id).set({
                          'approvalStatus': value,
                          'reviewedAt': FieldValue.serverTimestamp(),
                        }, SetOptions(merge: true));

                        final uid = (data['uid'] ?? '').toString();
                        if (uid.isNotEmpty) {
                          await db.collection('users').doc(uid).set({
                            'approvalStatus': value,
                          }, SetOptions(merge: true));
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'approved', child: Text('Approve')),
                        PopupMenuItem(value: 'rejected', child: Text('Reject')),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: PETROL_DARK,
      ),
    );
  }
}