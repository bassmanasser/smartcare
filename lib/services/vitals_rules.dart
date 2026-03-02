import '../services/vitals_service.dart';

class VitalsRuleResult {
  final String type;
  final String severity; // low/medium/high
  final String message;

  VitalsRuleResult({
    required this.type,
    required this.severity,
    required this.message,
  });
}

class VitalsRules {
  static List<VitalsRuleResult> evaluate(VitalsDoc v) {
    final out = <VitalsRuleResult>[];

    // ===== Glucose (mg/dL) =====
    // low < 70, normal 70-140, medium 141-180, high >180
    if (v.glucose > 180) {
      out.add(VitalsRuleResult(
        type: 'glucose',
        severity: 'high',
        message: 'Your glucose is high. Drink water and take a short walk if possible.',
      ));
    } else if (v.glucose > 140) {
      out.add(VitalsRuleResult(
        type: 'glucose',
        severity: 'medium',
        message: 'Glucose is slightly high. Avoid sweets and drink water.',
      ));
    } else if (v.glucose > 0 && v.glucose < 70) {
      out.add(VitalsRuleResult(
        type: 'glucose',
        severity: 'high',
        message: 'Glucose is low. Take a snack/juice and recheck soon.',
      ));
    }

    // ===== SpO2 (%) =====
    if (v.spo2 > 0 && v.spo2 < 90) {
      out.add(VitalsRuleResult(
        type: 'spo2',
        severity: 'high',
        message: 'SpO₂ is very low. Sit down, breathe slowly, and consider SOS if symptoms persist.',
      ));
    } else if (v.spo2 > 0 && v.spo2 < 92) {
      out.add(VitalsRuleResult(
        type: 'spo2',
        severity: 'medium',
        message: 'SpO₂ is low. Rest and monitor breathing.',
      ));
    }

    // ===== Heart Rate =====
    if (v.hr > 120) {
      out.add(VitalsRuleResult(
        type: 'hr',
        severity: 'medium',
        message: 'Heart rate is high. Rest and drink water. Monitor for dizziness.',
      ));
    } else if (v.hr > 0 && v.hr < 50) {
      out.add(VitalsRuleResult(
        type: 'hr',
        severity: 'medium',
        message: 'Heart rate is low. Rest and monitor how you feel.',
      ));
    }

    // ===== Temperature =====
    if (v.temperature >= 38.5) {
      out.add(VitalsRuleResult(
        type: 'temp',
        severity: 'high',
        message: 'High temperature. Hydrate well and consider medical advice if it continues.',
      ));
    } else if (v.temperature >= 37.6) {
      out.add(VitalsRuleResult(
        type: 'temp',
        severity: 'medium',
        message: 'Slight fever. Drink fluids and rest.',
      ));
    }

    // ===== Blood Pressure (اختياري) =====
    if (v.sys >= 180 || v.dia >= 120) {
      out.add(VitalsRuleResult(
        type: 'bp',
        severity: 'high',
        message: 'Blood pressure is dangerously high. Consider SOS/medical help.',
      ));
    } else if (v.sys >= 140 || v.dia >= 90) {
      out.add(VitalsRuleResult(
        type: 'bp',
        severity: 'medium',
        message: 'Blood pressure is elevated. Rest and avoid stress.',
      ));
    }

    // ===== Fall flag =====
    if (v.fallFlag == true) {
      out.add(VitalsRuleResult(
        type: 'fall',
        severity: 'high',
        message: 'Fall detected. Are you okay? If not, press SOS.',
      ));
    }

    return out;
  }
}
