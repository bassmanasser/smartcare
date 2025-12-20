import 'package:cloud_firestore/cloud_firestore.dart';

class MoodDoc {
  final String mood;
  final String? note;
  final DateTime timestamp;

  MoodDoc({required this.mood, this.note, required this.timestamp});

  factory MoodDoc.fromMap(Map<String, dynamic> m) {
    return MoodDoc(
      mood: (m['mood'] ?? '') as String,
      note: m['note'] as String?,
      timestamp: ((m['timestamp'] as Timestamp?)?.toDate()) ?? DateTime.now(),
    );
  }
}

class MoodService {
  final _db = FirebaseFirestore.instance;

  Stream<List<MoodDoc>> moodsStream(String patientId, {int limit = 50}) {
    return _db
        .collection('patients')
        .doc(patientId)
        .collection('moods')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((qs) => qs.docs.map((d) => MoodDoc.fromMap(d.data())).toList());
  }
}
