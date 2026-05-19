import 'package:cloud_firestore/cloud_firestore.dart';

class MoodRecord {
  String? id;
  final String patientId;
  final String mood;
  final String? note;
  final DateTime date;
  final double? sleepHours;
  final String? activity;
  final int? waterCups;
  final int? stress;
  final bool? exercise;

  MoodRecord({
    this.id,
    required this.patientId,
    required this.mood,
    this.note,
    required this.date,
    this.sleepHours,
    this.activity,
    this.waterCups,
    this.stress,
    this.exercise,
  });

  static DateTime _readDate(Map<String, dynamic> json) {
    final value = json['date'] ?? json['timestamp'] ?? json['createdAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  factory MoodRecord.fromJson(Map<String, dynamic> json, String id) {
    return MoodRecord(
      id: id,
      patientId: (json['patientId'] ?? '').toString(),
      mood: (json['mood'] ?? 'Neutral').toString(),
      note: json['note']?.toString(),
      date: _readDate(json),
      sleepHours: (json['sleepHours'] as num?)?.toDouble(),
      activity: json['activity']?.toString(),
      waterCups: (json['waterCups'] as num?)?.toInt(),
      stress: (json['stress'] as num?)?.toInt(),
      exercise: json['exercise'] as bool?,
    );
  }

  DateTime get timestamp => date;

  double get sleep => sleepHours ?? 0.0;

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'mood': mood,
      'note': note,
      'date': date.toIso8601String(),
      if (sleepHours != null) 'sleepHours': sleepHours,
      if (activity != null) 'activity': activity,
      if (waterCups != null) 'waterCups': waterCups,
      if (stress != null) 'stress': stress,
      if (exercise != null) 'exercise': exercise,
    };
  }
}
