import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mood_record.dart';

class MoodService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Singleton (اختياري، لتسهيل الوصول)
  static final MoodService _instance = MoodService._internal();
  static MoodService get instance => _instance;
  MoodService._internal();

  // جلب سجل المزاج
  Stream<List<MoodRecord>> moodsStream(String patientId, {int limit = 50}) {
    return _db
        .collection('users')
        .doc(patientId)
        .collection('moods')
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return MoodRecord.fromJson(data, doc.id);
          }).toList();
        });
  }

  // إضافة تسجيل جديد
  Future<void> addMood(MoodRecord record) async {
    await _db
        .collection('users')
        .doc(record.patientId)
        .collection('moods')
        .add(record.toJson());
  }
}
