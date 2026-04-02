import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class CareTeamScreen extends StatelessWidget {
  final String institutionId;

  const CareTeamScreen({
    super.key,
    required this.institutionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LIGHT_BG,
      appBar: AppBar(
        title: const Text('Care Team'),
        backgroundColor: PETROL_DARK,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('institutionId', isEqualTo: institutionId)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          final team = docs.where((doc) {
            final data = doc.data();
            final role = (data['role'] ?? data['staffRole'] ?? '').toString();
            return role == 'doctor' ||
                role == 'nurse' ||
                role == 'triage_staff' ||
                role == 'hospital_admin';
          }).toList();

          if (team.isEmpty) {
            return const Center(child: Text('No care team found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: team.length,
            itemBuilder: (context, index) {
              final data = team[index].data();

              final name = (data['name'] ?? 'Unknown').toString();
              final role =
                  (data['medicalRole'] ?? data['staffRole'] ?? 'Staff').toString();
              final department =
                  (data['departmentName'] ?? 'General').toString();
              final status =
                  (data['approvalStatus'] ?? 'pending').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: PETROL.withOpacity(0.12),
                      child: const Icon(Icons.person, color: PETROL_DARK),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$role • $department',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        color: status == 'approved'
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
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
}