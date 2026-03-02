class VitalSample {
  final String id;
  final String patientId;

  // القراءات الأساسية
  final int hr; // Heart Rate
  final int spo2; // Oxygen
  final int sys; // Blood Pressure (Systolic) - جديد
  final int dia; // Blood Pressure (Diastolic) - جديد
  
  final double glucose; // mg/dL - تم توحيد الاسم والنوع
  final double temperature; // Celsius - تم توحيد الاسم

  final bool fallFlag; // اكتشاف السقوط - جديد
  final DateTime timestamp; // تم توحيد الاسم

  VitalSample({
    required this.id,
    required this.patientId,
    required this.hr,
    required this.spo2,
    this.sys = 0,
    this.dia = 0,
    required this.glucose,
    required this.temperature,
    this.fallFlag = false,
    required this.timestamp,
  });

  factory VitalSample.fromJson(Map<String, dynamic> json, String id) {
    return VitalSample(
      id: json['id'] as String? ?? '',
      patientId: (json['patientId'] as String?) ?? '',
      hr: (json['hr'] as num?)?.toInt() ?? 0,
      spo2: (json['spo2'] as num?)?.toInt() ?? 0,
      sys: (json['sys'] as num?)?.toInt() ?? 0,
      dia: (json['dia'] as num?)?.toInt() ?? 0,
      // التعامل مع الاحتمالين (الاسم القديم والجديد)
      glucose: (json['glucose'] as num?)?.toDouble() ?? (json['glucose_mgdl'] as num?)?.toDouble() ?? 0.0,
      temperature: (json['temperature'] as num?)?.toDouble() ?? (json['temp_c'] as num?)?.toDouble() ?? 0.0,
      fallFlag: json['fallFlag'] as bool? ?? false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (json['t'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  get glucoseMgdl => null;

  double? get tempC => null;

  get temp => null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'hr': hr,
      'spo2': spo2,
      'sys': sys,
      'dia': dia,
      'glucose': glucose,
      'temperature': temperature,
      'fallFlag': fallFlag,
      't': timestamp.millisecondsSinceEpoch, // تخزين الوقت كـ رقم لسهولة الترتيب
    };
  }
}