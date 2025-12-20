import 'package:cloud_firestore/cloud_firestore.dart';

class Vitals {
  final int hr;
  final int spo2;
  final int sys;
  final int dia;
  final double glucose;
  final double temperature;
  final bool fallFlag;
  final DateTime? createdAt;

  Vitals({
    required this.hr,
    required this.spo2,
    required this.sys,
    required this.dia,
    required this.glucose,
    required this.temperature,
    required this.fallFlag,
    this.createdAt,
  });

  factory Vitals.fromJson(Map<String, dynamic> json) {
    final ts = json['createdAt'];
    return Vitals(
      hr: (json['hr'] ?? 0) as int,
      spo2: (json['spo2'] ?? 0) as int,
      sys: (json['sys'] ?? 0) as int,
      dia: (json['dia'] ?? 0) as int,
      glucose: (json['glucose'] ?? 0).toDouble(),
      temperature: (json['temperature'] ?? 0).toDouble(),
      fallFlag: (json['fallFlag'] ?? false) as bool,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "hr": hr,
      "spo2": spo2,
      "sys": sys,
      "dia": dia,
      "glucose": glucose,
      "temperature": temperature,
      "fallFlag": fallFlag,
      "createdAt": FieldValue.serverTimestamp(),
    };
  }
}
