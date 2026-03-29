class DispatchRules {
  // Oxygen
  static const int lowSpo2Threshold = 92;
  static const int criticalSpo2Threshold = 88;

  // Temperature
  static const double feverThreshold = 38.0;
  static const double criticalFeverThreshold = 39.5;

  // Glucose
  static const double lowGlucoseThreshold = 70;
  static const double highGlucoseThreshold = 180;
  static const double criticalHighGlucoseThreshold = 250;
  static const double criticalLowGlucoseThreshold = 55;

  // Heart rate
  static const int lowHrThreshold = 50;
  static const int highHrThreshold = 120;
  static const int criticalLowHrThreshold = 40;
  static const int criticalHighHrThreshold = 140;

  // Blood pressure
  static const int highSysThreshold = 140;
  static const int criticalSysThreshold = 180;
  static const int highDiaThreshold = 90;
  static const int criticalDiaThreshold = 120;

  // Trend windows
  static const int recentWindowSize = 10;
  static const int repeatedAbnormalMinCount = 3;

  // Case statuses
  static const String caseStatusStable = 'stable';
  static const String caseStatusAttention = 'needs_attention';
  static const String caseStatusHighRisk = 'high_risk';
  static const String caseStatusEmergency = 'emergency';
}