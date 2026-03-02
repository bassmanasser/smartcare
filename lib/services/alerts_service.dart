import 'package:cloud_firestore/cloud_firestore.dart';

class AlertDoc {
  final String patientId;
  final String type;      // glucose/spo2/hr/temp/bp/fall
  final String message;
  final String severity;  // low/medium/high
  final DateTime timestamp;

  AlertDoc({
    required this.patientId,
    required this.type,
    required this.message,
    required this.severity,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'type': type,
      'message': message,
      'severity': severity,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory AlertDoc.fromMap(Map<String, dynamic> m) {
    final ts = (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    return AlertDoc(
      patientId: (m['patientId'] as String?) ?? '',
      type: (m['type'] as String?) ?? '',
      message: (m['message'] as String?) ?? '',
      severity: (m['severity'] as String?) ?? 'low',
      timestamp: ts,
    );
  }
}

class AlertsService {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _col(String patientId) =>
      _db.collection('patients').doc(patientId).collection('alerts');

  Stream<List<AlertDoc>> alertsStream(String patientId, {int limit = 50}) {
    return _col(patientId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => AlertDoc.fromMap(d.data())).toList());
  }

  Future<void> addAlert(String patientId, AlertDoc alert) async {
    await _col(patientId).add(alert.toMap());
  }

  /// منع التكرار (مثلاً لو نفس الرسالة اتكتبت من ثواني)
  Future<bool> recentlyAddedSameAlert({
    required String patientId,
    required String type,
    required String severity,
    required int withinSeconds,
  }) async {
    final since = DateTime.now().subtract(Duration(seconds: withinSeconds));
    final q = await _col(patientId)
        .where('type', isEqualTo: type)
        .where('severity', isEqualTo: severity)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(since))
        .limit(1)
        .get();

    return q.docs.isNotEmpty;
  }
}
