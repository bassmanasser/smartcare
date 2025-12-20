import 'package:cloud_firestore/cloud_firestore.dart';

class VitalsDoc {
  final int hr;
  final int spo2;
  final int sys;
  final int dia;
  final double glucose;
  final double temperature;
  final bool fallFlag;
  final DateTime timestamp;

  VitalsDoc({
    required this.hr,
    required this.spo2,
    required this.sys,
    required this.dia,
    required this.glucose,
    required this.temperature,
    required this.fallFlag,
    required this.timestamp,
  });

  factory VitalsDoc.fromMap(Map<String, dynamic> m) {
    final ts = (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    return VitalsDoc(
      hr: (m['hr'] ?? 0) as int,
      spo2: (m['spo2'] ?? 0) as int,
      sys: (m['sys'] ?? 0) as int,
      dia: (m['dia'] ?? 0) as int,
      glucose: (m['glucose'] ?? 0).toDouble(),
      temperature: (m['temperature'] ?? 0).toDouble(),
      fallFlag: (m['fallFlag'] ?? false) as bool,
      timestamp: ts,
    );
  }
}

class VitalsService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String patientId) =>
      _db.collection('patients').doc(patientId).collection('vitals');

  // ✅ latest (single doc)
  Stream<VitalsDoc?> latestVitalsStream(String patientId) {
    return _col(patientId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((qs) {
      if (qs.docs.isEmpty) return null;
      return VitalsDoc.fromMap(qs.docs.first.data());
    });
  }

  // ✅ list (history)
  Stream<List<VitalsDoc>> vitalsStream(String patientId, {int limit = 50}) {
    return _col(patientId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((qs) => qs.docs.map((d) => VitalsDoc.fromMap(d.data())).toList());
  }
}
