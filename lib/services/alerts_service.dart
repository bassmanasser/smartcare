import 'package:cloud_firestore/cloud_firestore.dart';

class AlertDoc {
  final String message;
  final String severity; // high / medium / low
  final DateTime timestamp;

  AlertDoc({required this.message, required this.severity, required this.timestamp});

  factory AlertDoc.fromMap(Map<String, dynamic> m) {
    return AlertDoc(
      message: (m['message'] ?? '') as String,
      severity: (m['severity'] ?? 'low') as String,
      timestamp: ((m['timestamp'] as Timestamp?)?.toDate()) ?? DateTime.now(),
    );
  }
}

class AlertsService {
  final _db = FirebaseFirestore.instance;

  Stream<List<AlertDoc>> alertsStream(String patientId, {int limit = 50}) {
    return _db
        .collection('patients')
        .doc(patientId)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((qs) => qs.docs.map((d) => AlertDoc.fromMap(d.data())).toList());
  }
}
