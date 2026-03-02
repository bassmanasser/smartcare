import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApprovedDoctorsListScreen extends StatelessWidget {
  const ApprovedDoctorsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection("doctors")
        .where("verificationStatus", isEqualTo: "approved")
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text("Doctors")),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text("Error loading doctors"));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text("No approved doctors yet"));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final name = d["name"] ?? "Doctor";
              final main = d["mainSpecialty"] ?? "";
              final sub = d["subSpecialty"] ?? "";

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.medical_services)),
                title: Text(name),
                subtitle: Text("$main • $sub"),
                onTap: () {
                  // افتحي بروفايل الدكتور لو عندك شاشة
                  // Navigator.push(...)
                },
              );
            },
          );
        },
      ),
    );
  }
}