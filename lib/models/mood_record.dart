class MoodRecord {
  final String id;
  final String patientId;
  final String mood; // 'Happy', 'Sad', 'Stressed'...
  final String? note;
  final DateTime timestamp;

  MoodRecord({
    required this.id,
    required this.patientId,
    required this.mood,
    this.note,
    required this.timestamp,
  });

  factory MoodRecord.fromJson(Map<String, dynamic> json) {
    return MoodRecord(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String,
      mood: json['mood'] as String? ?? 'Neutral',
      note: json['note'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['t'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  get stress => null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'mood': mood,
      'note': note,
      't': timestamp.millisecondsSinceEpoch,
    };
  }
}
