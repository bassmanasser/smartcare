import 'package:flutter/material.dart';

class Medication {
  final String id;
  final String patientId;
  final String name;
  final String dosage;
  final String frequency;
  final bool active;

  /// وقت التذكير (اختياري)
  final TimeOfDay? reminderTime;

  /// هل التذكير مفعّل؟
  final bool reminderEnabled;

  Medication({
    required this.id,
    required this.patientId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.active,
    this.reminderTime,
    this.reminderEnabled = false,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    // نقرأ الساعة والدقيقة لو موجودين من الـ Firestore
    final hour = json['reminderHour'] as int?;
    final minute = json['reminderMinute'] as int?;
    TimeOfDay? reminderTime;
    if (hour != null && minute != null) {
      reminderTime = TimeOfDay(hour: hour, minute: minute);
    }

    return Medication(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      frequency: json['frequency'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      reminderTime: reminderTime,
      reminderEnabled: json['reminderEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientId': patientId,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'active': active,
      if (reminderTime != null) ...{
        'reminderHour': reminderTime!.hour,
        'reminderMinute': reminderTime!.minute,
      },
      'reminderEnabled': reminderEnabled,
    };
  }
}
