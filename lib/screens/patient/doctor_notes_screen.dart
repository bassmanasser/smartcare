import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/doctor_note.dart';
import '../../utils/constants.dart';

class DoctorNotesScreen extends StatelessWidget {
  final String patientId;
  const DoctorNotesScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor's Notes"),
        backgroundColor: PETROL_DARK,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // الاستماع المباشر لمجموعة 'notes'
        stream: FirebaseFirestore.instance
            .collection('notes')
            .where('patientId', isEqualTo: patientId)
            .orderBy('date', descending: true) // الأحدث فوق
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_alt_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text("No notes from your doctor yet.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              // إضافة ID للبيانات عشان الموديل
              data['id'] = docs[index].id;
              final note = DoctorNote.fromJson(data);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medical_services, size: 18, color: PETROL),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat.yMMMd().add_jm().format(note.date),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Text(
                        note.text,
                        style: const TextStyle(fontSize: 16, height: 1.4),
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