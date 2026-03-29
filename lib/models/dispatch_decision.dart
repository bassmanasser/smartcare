import 'package:cloud_firestore/cloud_firestore.dart';

enum DispatchUrgency {
  routine,
  priority,
  urgent,
  emergency,
}

enum DispatchAction {
  selfCare,
  doctorConsult,
  specialistReferral,
  hospitalEscalation,
}

extension DispatchUrgencyX on DispatchUrgency {
  String get key {
    switch (this) {
      case DispatchUrgency.routine:
        return 'routine';
      case DispatchUrgency.priority:
        return 'priority';
      case DispatchUrgency.urgent:
        return 'urgent';
      case DispatchUrgency.emergency:
        return 'emergency';
    }
  }

  static DispatchUrgency fromString(String? value) {
    switch (value) {
      case 'priority':
        return DispatchUrgency.priority;
      case 'urgent':
        return DispatchUrgency.urgent;
      case 'emergency':
        return DispatchUrgency.emergency;
      case 'routine':
      default:
        return DispatchUrgency.routine;
    }
  }
}

extension DispatchActionX on DispatchAction {
  String get key {
    switch (this) {
      case DispatchAction.selfCare:
        return 'self_care';
      case DispatchAction.doctorConsult:
        return 'doctor_consult';
      case DispatchAction.specialistReferral:
        return 'specialist_referral';
      case DispatchAction.hospitalEscalation:
        return 'hospital_escalation';
    }
  }

  static DispatchAction fromString(String? value) {
    switch (value) {
      case 'doctor_consult':
        return DispatchAction.doctorConsult;
      case 'specialist_referral':
        return DispatchAction.specialistReferral;
      case 'hospital_escalation':
        return DispatchAction.hospitalEscalation;
      case 'self_care':
      default:
        return DispatchAction.selfCare;
    }
  }
}

class DispatchDecision {
  final String id;
  final String patientId;
  final String specialty;
  final DispatchUrgency urgency;
  final DispatchAction action;
  final String explanation;
  final String? sourceAssessmentId;
  final DateTime createdAt;

  const DispatchDecision({
    required this.id,
    required this.patientId,
    required this.specialty,
    required this.urgency,
    required this.action,
    required this.explanation,
    required this.sourceAssessmentId,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'specialty': specialty,
      'urgency': urgency.key,
      'action': action.key,
      'explanation': explanation,
      'sourceAssessmentId': sourceAssessmentId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DispatchDecision.fromJson(Map<String, dynamic> json, String id) {
    final rawCreatedAt = json['createdAt'];
    DateTime createdAt;

    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return DispatchDecision(
      id: id,
      patientId: (json['patientId'] ?? '').toString(),
      specialty: (json['specialty'] ?? 'general').toString(),
      urgency: DispatchUrgencyX.fromString(json['urgency']?.toString()),
      action: DispatchActionX.fromString(json['action']?.toString()),
      explanation: (json['explanation'] ?? '').toString(),
      sourceAssessmentId: json['sourceAssessmentId']?.toString(),
      createdAt: createdAt,
    );
  }

  DispatchDecision copyWith({
    String? id,
    String? patientId,
    String? specialty,
    DispatchUrgency? urgency,
    DispatchAction? action,
    String? explanation,
    String? sourceAssessmentId,
    DateTime? createdAt,
  }) {
    return DispatchDecision(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      specialty: specialty ?? this.specialty,
      urgency: urgency ?? this.urgency,
      action: action ?? this.action,
      explanation: explanation ?? this.explanation,
      sourceAssessmentId: sourceAssessmentId ?? this.sourceAssessmentId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}