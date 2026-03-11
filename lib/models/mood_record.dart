class MoodRecord {
  String? id;
  final String patientId;
  final String mood;
  final String? note;
  final DateTime date;

  MoodRecord({
    this.id,
    required this.patientId,
    required this.mood,
    this.note,
    required this.date,
  });

  // تحويل البيانات القادمة من Firestore
  factory MoodRecord.fromJson(Map<String, dynamic> json, String id) {
    return MoodRecord(
      id: json['id'],
      patientId: json['patientId'] ?? '',
      mood: json['mood'] ?? 'Neutral',
      note: json['note'],
        // التعامل مع اختلاف صيغ الوقت في Firebase
        date: json['date'] != null 
          ? DateTime.tryParse(json['date']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  get timestamp => null;

  get stress => null;

  // تحويل البيانات لإرسالها لـ Firestore
  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'mood': mood,
      'note': note,
      'date': date.toIso8601String(),
    };
  }
}