import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class AlertsHistoryScreen extends StatelessWidget {
  final String patientId;
  const AlertsHistoryScreen({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    final stream = FirebaseFirestore.instance
        .collection('patients')
        .doc(patientId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts History'),
        backgroundColor: PETROL_DARK,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('No alerts.'));
          }

          final docs = snap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              final msg = (d['message'] ?? '').toString();
              final sev = (d['severity'] ?? 'low').toString().toLowerCase();
              final ts = (d['timestamp'] as Timestamp?)?.toDate();

              Color c;
              if (sev == 'high') {
                c = Colors.redAccent;
              } else if (sev == 'medium') {
                c = Colors.orangeAccent;
              } else {
                c = Colors.amber;
              }

              final date = ts == null
                  ? '--'
                  : '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}  ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

              return Card(
                child: ListTile(
                  leading: Icon(Icons.warning_amber_rounded, color: c),
                  title: Text(msg),
                  subtitle: Text(date),
                  trailing: Text(
                    sev.toUpperCase(),
                    style: TextStyle(color: c, fontWeight: FontWeight.bold),
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
