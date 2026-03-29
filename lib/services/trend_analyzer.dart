import '../config/dispatch_rules.dart';
import '../models/vital_sample.dart';

class TrendSnapshot {
  final bool repeatedLowSpo2;
  final bool repeatedFever;
  final bool repeatedHighGlucose;
  final bool repeatedLowGlucose;
  final bool repeatedAbnormalHr;
  final bool repeatedHighBp;

  const TrendSnapshot({
    required this.repeatedLowSpo2,
    required this.repeatedFever,
    required this.repeatedHighGlucose,
    required this.repeatedLowGlucose,
    required this.repeatedAbnormalHr,
    required this.repeatedHighBp,
  });
}

class TrendAnalyzer {
  const TrendAnalyzer();

  TrendSnapshot analyze(List<VitalSample> history, VitalSample latest) {
    final items = [...history, latest];
    final recent = items.length <= DispatchRules.recentWindowSize
        ? items
        : items.sublist(items.length - DispatchRules.recentWindowSize);

    int lowSpo2Count = 0;
    int feverCount = 0;
    int highGlucoseCount = 0;
    int lowGlucoseCount = 0;
    int abnormalHrCount = 0;
    int highBpCount = 0;

    for (final s in recent) {
      if (s.spo2 > 0 && s.spo2 < DispatchRules.lowSpo2Threshold) {
        lowSpo2Count++;
      }

      if (s.temperature >= DispatchRules.feverThreshold) {
        feverCount++;
      }

      if (s.glucose > 0 &&
          s.glucose >= DispatchRules.highGlucoseThreshold) {
        highGlucoseCount++;
      }

      if (s.glucose > 0 &&
          s.glucose <= DispatchRules.lowGlucoseThreshold) {
        lowGlucoseCount++;
      }

      final hrAbnormal =
          (s.hr > 0 && s.hr < DispatchRules.lowHrThreshold) ||
          (s.hr > DispatchRules.highHrThreshold);
      if (hrAbnormal) {
        abnormalHrCount++;
      }

      final bpAbnormal =
          s.sys >= DispatchRules.highSysThreshold ||
          s.dia >= DispatchRules.highDiaThreshold;
      if (bpAbnormal) {
        highBpCount++;
      }
    }

    return TrendSnapshot(
      repeatedLowSpo2:
          lowSpo2Count >= DispatchRules.repeatedAbnormalMinCount,
      repeatedFever:
          feverCount >= DispatchRules.repeatedAbnormalMinCount,
      repeatedHighGlucose:
          highGlucoseCount >= DispatchRules.repeatedAbnormalMinCount,
      repeatedLowGlucose:
          lowGlucoseCount >= DispatchRules.repeatedAbnormalMinCount,
      repeatedAbnormalHr:
          abnormalHrCount >= DispatchRules.repeatedAbnormalMinCount,
      repeatedHighBp:
          highBpCount >= DispatchRules.repeatedAbnormalMinCount,
    );
  }
}