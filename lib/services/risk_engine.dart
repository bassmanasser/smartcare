import '../config/dispatch_rules.dart';
import '../models/risk_assessment.dart';
import '../models/vital_sample.dart';
import 'trend_analyzer.dart';

class RiskEngine {
  final TrendAnalyzer trendAnalyzer;

  const RiskEngine({
    this.trendAnalyzer = const TrendAnalyzer(),
  });

  RiskAssessment assess({
    required String patientId,
    required VitalSample latest,
    required List<VitalSample> history,
    bool arrhythmiaAbnormal = false,
    bool respiratoryAbnormal = false,
  }) {
    final trend = trendAnalyzer.analyze(history, latest);

    int score = 0;
    final reasons = <String>[];
    final triggered = <String>[];

    if (latest.fallFlag) {
      score += 100;
      reasons.add('Fall detected from wearable sensor');
      triggered.add('fall');
    }

    if (latest.spo2 > 0 && latest.spo2 < DispatchRules.criticalSpo2Threshold) {
      score += 60;
      reasons.add('Critical oxygen saturation detected (${latest.spo2}%)');
      triggered.add('spo2');
    } else if (latest.spo2 > 0 &&
        latest.spo2 < DispatchRules.lowSpo2Threshold) {
      score += 30;
      reasons.add('Low oxygen saturation detected (${latest.spo2}%)');
      triggered.add('spo2');
    }

    if (trend.repeatedLowSpo2) {
      score += 20;
      reasons.add('Repeated low oxygen readings in recent trend');
      if (!triggered.contains('spo2')) triggered.add('spo2');
    }

    if (latest.temperature >= DispatchRules.criticalFeverThreshold) {
      score += 35;
      reasons.add(
        'Very high temperature detected (${latest.temperature.toStringAsFixed(1)}°C)',
      );
      triggered.add('temperature');
    } else if (latest.temperature >= DispatchRules.feverThreshold) {
      score += 15;
      reasons.add(
        'Fever detected (${latest.temperature.toStringAsFixed(1)}°C)',
      );
      triggered.add('temperature');
    }

    if (trend.repeatedFever) {
      score += 10;
      reasons.add('Repeated fever pattern detected');
      if (!triggered.contains('temperature')) triggered.add('temperature');
    }

    if (latest.glucose > 0 &&
        latest.glucose >= DispatchRules.criticalHighGlucoseThreshold) {
      score += 40;
      reasons.add(
        'Critical high glucose detected (${latest.glucose.toStringAsFixed(0)} mg/dL)',
      );
      triggered.add('glucose');
    } else if (latest.glucose > 0 &&
        latest.glucose >= DispatchRules.highGlucoseThreshold) {
      score += 20;
      reasons.add(
        'High glucose detected (${latest.glucose.toStringAsFixed(0)} mg/dL)',
      );
      triggered.add('glucose');
    }

    if (latest.glucose > 0 &&
        latest.glucose <= DispatchRules.criticalLowGlucoseThreshold) {
      score += 45;
      reasons.add(
        'Critical low glucose detected (${latest.glucose.toStringAsFixed(0)} mg/dL)',
      );
      triggered.add('glucose');
    } else if (latest.glucose > 0 &&
        latest.glucose <= DispatchRules.lowGlucoseThreshold) {
      score += 25;
      reasons.add(
        'Low glucose detected (${latest.glucose.toStringAsFixed(0)} mg/dL)',
      );
      triggered.add('glucose');
    }

    if (trend.repeatedHighGlucose) {
      score += 12;
      reasons.add('Repeated high glucose pattern detected');
      if (!triggered.contains('glucose')) triggered.add('glucose');
    }

    if (trend.repeatedLowGlucose) {
      score += 12;
      reasons.add('Repeated low glucose pattern detected');
      if (!triggered.contains('glucose')) triggered.add('glucose');
    }

    final hrCriticalHigh = latest.hr >= DispatchRules.criticalHighHrThreshold;
    final hrCriticalLow =
        latest.hr > 0 && latest.hr <= DispatchRules.criticalLowHrThreshold;
    final hrAbnormalHigh = latest.hr >= DispatchRules.highHrThreshold;
    final hrAbnormalLow =
        latest.hr > 0 && latest.hr <= DispatchRules.lowHrThreshold;

    if (hrCriticalHigh || hrCriticalLow) {
      score += 35;
      reasons.add('Critical heart rate detected (${latest.hr} bpm)');
      triggered.add('hr');
    } else if (hrAbnormalHigh || hrAbnormalLow) {
      score += 18;
      reasons.add('Abnormal heart rate detected (${latest.hr} bpm)');
      triggered.add('hr');
    }

    if (trend.repeatedAbnormalHr) {
      score += 12;
      reasons.add('Repeated abnormal heart-rate trend detected');
      if (!triggered.contains('hr')) triggered.add('hr');
    }

    if (latest.sys >= DispatchRules.criticalSysThreshold ||
        latest.dia >= DispatchRules.criticalDiaThreshold) {
      score += 35;
      reasons.add(
        'Critical blood pressure detected (${latest.sys}/${latest.dia})',
      );
      triggered.add('bp');
    } else if (latest.sys >= DispatchRules.highSysThreshold ||
        latest.dia >= DispatchRules.highDiaThreshold) {
      score += 18;
      reasons.add(
        'High blood pressure detected (${latest.sys}/${latest.dia})',
      );
      triggered.add('bp');
    }

    if (trend.repeatedHighBp) {
      score += 10;
      reasons.add('Repeated high blood-pressure trend detected');
      if (!triggered.contains('bp')) triggered.add('bp');
    }

    if (arrhythmiaAbnormal) {
      score += 28;
      reasons.add('Arrhythmia analysis indicates abnormal rhythm');
      triggered.add('arrhythmia');
    }

    if (respiratoryAbnormal) {
      score += 24;
      reasons.add('Respiratory analysis indicates abnormal condition');
      triggered.add('respiratory');
    }

    RiskLevel level;
    if (latest.fallFlag ||
        score >= 85 ||
        (latest.spo2 > 0 &&
            latest.spo2 < DispatchRules.criticalSpo2Threshold)) {
      level = RiskLevel.emergency;
    } else if (score >= 50) {
      level = RiskLevel.highRisk;
    } else if (score >= 20) {
      level = RiskLevel.attention;
    } else {
      level = RiskLevel.normal;
    }

    if (reasons.isEmpty) {
      reasons.add('Vitals are currently within acceptable monitoring range');
    }

    return RiskAssessment(
      id: '',
      patientId: patientId,
      riskLevel: level,
      score: score,
      reasons: reasons,
      triggeredVitals: triggered,
      createdAt: DateTime.now(),
    );
  }
}