class VitalSample {
  final String id;
  final String patientId;
  final int hr;              // Heart rate (bpm)
  final int spo2;            // Oxygen saturation (%)
  final int? glucoseMgdl;    // Blood glucose (mg/dL)
  final double? tempC;       // Temperature (°C)
  final DateTime timestamp;

  VitalSample({
    required this.id,
    required this.patientId,
    required this.hr,
    required this.spo2,
    this.glucoseMgdl,
    this.tempC,
    required this.timestamp,
  });

  factory VitalSample.fromJson(Map<String, dynamic> json) {
    return VitalSample(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String,
      hr: (json['hr'] as num?)?.toInt() ?? 0,
      spo2: (json['spo2'] as num?)?.toInt() ?? 0,
      glucoseMgdl: (json['glucose_mgdl'] as num?)?.toInt(),
      tempC: (json['temp_c'] as num?)?.toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['t'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  get temp => null;

  get glucose => null;

  get temperature => null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'hr': hr,
      'spo2': spo2,
      'glucose_mgdl': glucoseMgdl,
      'temp_c': tempC,
      't': timestamp.millisecondsSinceEpoch,
    };
  }
}
