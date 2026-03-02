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
      hr: (m['hr'] as num?)?.toInt() ?? 0,
      spo2: (m['spo2'] as num?)?.toInt() ?? 0,
      sys: (m['sys'] as num?)?.toInt() ?? 0,
      dia: (m['dia'] as num?)?.toInt() ?? 0,
      glucose: (m['glucose'] as num?)?.toDouble() ?? 0.0,
      temperature: (m['temperature'] as num?)?.toDouble() ?? 0.0,
      fallFlag: (m['fallFlag'] as bool?) ?? false,
      timestamp: ts,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hr': hr,
      'spo2': spo2,
      'sys': sys,
      'dia': dia,
      'glucose': glucose,
      'temperature': temperature,
      'fallFlag': fallFlag,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class VitalsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String patientId) {
    return _db.collection('patients').doc(patientId).collection('vitals');
  }

  /// ✅ Stream آخر قراءة (علشان Home Cards)
  Stream<VitalsDoc?> latestVitalsStream(String patientId) {
    return _col(patientId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return VitalsDoc.fromMap(snap.docs.first.data());
    });
  }

  /// ✅ Stream history (علشان Vitals History / Charts)
  Stream<List<VitalsDoc>> vitalsStream(String patientId, {int limit = 50}) {
    return _col(patientId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => VitalsDoc.fromMap(d.data())).toList());
  }

  /// ✅ إضافة قراءة (هنستخدمها لما نربط BLE ESP32)
  Future<void> addVital(String patientId, VitalsDoc doc) async {
    await _col(patientId).add(doc.toMap());
  }

  Future<void> pushVitals(String patientId, VitalsDoc vitals) async {}
}
