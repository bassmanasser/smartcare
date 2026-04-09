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

  Stream<QuerySnapshot<Map<String, dynamic>>> _requestsStream() {
    return FirebaseFirestore.instance
        .collection('staff_requests')
        .where('institutionId', isEqualTo: widget.institutionId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
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
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Approval failed: $e')));
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
        }, SetOptions(merge: true));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Reject failed: $e')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Approvals')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _requestsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final title = (data['name'] ?? data['fullName'] ?? 'Unknown').toString();
              final subtitle = <String>[
                'Role: ${(data['role'] ?? '-').toString()}',
                if ((data['department'] ?? '').toString().isNotEmpty)
                  'Department: ${data['department']}',
                if ((data['email'] ?? '').toString().isNotEmpty)
                  'Email: ${data['email']}',
                if ((data['employeeId'] ?? '').toString().isNotEmpty)
                  'Employee ID: ${data['employeeId']}',
                if ((data['licenseNumber'] ?? '').toString().isNotEmpty)
                  'License: ${data['licenseNumber']}',
              ].join('\n');

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.badge_outlined)),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(subtitle),
                        isThreeLine: true,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _processing ? null : () => _reject(doc),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _processing ? null : () => _approve(doc),
                              icon: const Icon(Icons.check),
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
    );
  }
}
