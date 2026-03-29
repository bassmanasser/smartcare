import 'package:cloud_firestore/cloud_firestore.dart';

enum RiskLevel {
  normal,
  attention,
  highRisk,
  emergency,
}

extension RiskLevelX on RiskLevel {
  String get key {
    switch (this) {
      case RiskLevel.normal:
        return 'normal';
      case RiskLevel.attention:
        return 'attention';
      case RiskLevel.highRisk:
        return 'high_risk';
      case RiskLevel.emergency:
        return 'emergency';
    }
  }

  static RiskLevel fromString(String? value) {
    switch (value) {
      case 'attention':
        return RiskLevel.attention;
      case 'high_risk':
        return RiskLevel.highRisk;
      case 'emergency':
        return RiskLevel.emergency;
      case 'normal':
      default:
        return RiskLevel.normal;
    }
  }
}

class RiskAssessment {
  final String id;
  final String patientId;
  final RiskLevel riskLevel;
  final int score;
  final List<String> reasons;
  final List<String> triggeredVitals;
  final DateTime createdAt;

  const RiskAssessment({
    required this.id,
    required this.patientId,
    required this.riskLevel,
    required this.score,
    required this.reasons,
    required this.triggeredVitals,
    required this.createdAt,
  });

  bool get isEmergency => riskLevel == RiskLevel.emergency;
  bool get isHighRisk => riskLevel == RiskLevel.highRisk;
  bool get needsAttention =>
      riskLevel == RiskLevel.attention ||
      riskLevel == RiskLevel.highRisk ||
      riskLevel == RiskLevel.emergency;

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'riskLevel': riskLevel.key,
      'score': score,
      'reasons': reasons,
      'triggeredVitals': triggeredVitals,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RiskAssessment.fromJson(Map<String, dynamic> json, String id) {
    final rawCreatedAt = json['createdAt'];
    DateTime createdAt;

    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return RiskAssessment(
      id: id,
      patientId: (json['patientId'] ?? '').toString(),
      riskLevel: RiskLevelX.fromString(json['riskLevel']?.toString()),
      score: (json['score'] as num?)?.toInt() ?? 0,
      reasons: List<String>.from(json['reasons'] ?? const []),
      triggeredVitals: List<String>.from(json['triggeredVitals'] ?? const []),
      createdAt: createdAt,
    );
  }

  RiskAssessment copyWith({
    String? id,
    String? patientId,
    RiskLevel? riskLevel,
    int? score,
    List<String>? reasons,
    List<String>? triggeredVitals,
    DateTime? createdAt,
  }) {
    return RiskAssessment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      riskLevel: riskLevel ?? this.riskLevel,
      score: score ?? this.score,
      reasons: reasons ?? this.reasons,
      triggeredVitals: triggeredVitals ?? this.triggeredVitals,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}