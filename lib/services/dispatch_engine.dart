import '../models/dispatch_decision.dart';
import '../models/risk_assessment.dart';

class DispatchEngine {
  const DispatchEngine();

  DispatchDecision decide({
    required String patientId,
    required RiskAssessment assessment,
    bool arrhythmiaAbnormal = false,
    bool respiratoryAbnormal = false,
  }) {
    String specialty = 'general';
    DispatchUrgency urgency = DispatchUrgency.routine;
    DispatchAction action = DispatchAction.selfCare;
    String explanation = 'Continue home monitoring and routine follow-up.';

    final triggers = assessment.triggeredVitals;

    if (assessment.riskLevel == RiskLevel.emergency) {
      urgency = DispatchUrgency.emergency;
      action = DispatchAction.hospitalEscalation;
      specialty = 'emergency';
      explanation =
          'Emergency escalation is recommended because the system detected a severe or potentially unstable condition.';
    } else if (assessment.riskLevel == RiskLevel.highRisk) {
      urgency = DispatchUrgency.urgent;
      action = DispatchAction.specialistReferral;
      explanation =
          'Urgent specialist review is recommended due to multiple abnormal readings or repeated risk patterns.';
    } else if (assessment.riskLevel == RiskLevel.attention) {
      urgency = DispatchUrgency.priority;
      action = DispatchAction.doctorConsult;
      explanation =
          'A medical consultation is recommended to review the recent abnormal readings.';
    }

    if (arrhythmiaAbnormal || triggers.contains('arrhythmia')) {
      specialty = 'cardiology';
      if (assessment.riskLevel != RiskLevel.normal) {
        explanation =
            'The patient should be routed to Cardiology because the rhythm pattern appears abnormal.';
      }
    } else if (respiratoryAbnormal || triggers.contains('respiratory')) {
      specialty = 'chest';
      if (assessment.riskLevel != RiskLevel.normal) {
        explanation =
            'The patient should be routed to Chest/Respiratory care because breathing-related abnormalities were detected.';
      }
    } else if (triggers.contains('glucose')) {
      specialty = 'endocrinology';
      if (assessment.riskLevel != RiskLevel.normal) {
        explanation =
            'The patient should be routed to Endocrinology due to glucose instability.';
      }
    } else if (triggers.contains('spo2')) {
      specialty = 'chest';
      if (assessment.riskLevel != RiskLevel.normal) {
        explanation =
            'The patient should be routed to respiratory/chest evaluation because oxygen saturation is below normal.';
      }
    } else if (triggers.contains('hr') || triggers.contains('bp')) {
      specialty = 'internal_medicine';
      if (assessment.riskLevel != RiskLevel.normal) {
        explanation =
            'The patient should be reviewed by Internal Medicine because cardiovascular indicators are outside normal range.';
      }
    }

    if (assessment.riskLevel == RiskLevel.normal) {
      specialty = 'general';
      urgency = DispatchUrgency.routine;
      action = DispatchAction.selfCare;
      explanation =
          'No immediate medical dispatch is required. Continue monitoring and routine follow-up.';
    }

    return DispatchDecision(
      id: '',
      patientId: patientId,
      specialty: specialty,
      urgency: urgency,
      action: action,
      explanation: explanation,
      sourceAssessmentId: assessment.id.isEmpty ? null : assessment.id,
      createdAt: DateTime.now(),
    );
  }
}