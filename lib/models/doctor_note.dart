class DoctorNote {
  final String id;
  final String patientId;
  final String doctorId;
  final String text;
  final DateTime date;

  DoctorNote({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.text,
    required this.date,
  });

  factory DoctorNote.fromJson(Map<String, dynamic> json, String id) {
    return DoctorNote(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String,
      doctorId: json['doctorId'] as String,
      text: json['text'] as String? ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(
        (json['date'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'doctorId': doctorId,
      'text': text,
      'date': date.millisecondsSinceEpoch,
    };
  }
}
