class GlucoseAdvice {
  final String title;
  final String message;
  final String severity; // low, normal, medium, high
  GlucoseAdvice(this.title, this.message, this.severity);
}

class GlucoseAdvisor {
  static GlucoseAdvice getAdvice(double glucoseMgdl) {
    if (glucoseMgdl < 70) {
      return GlucoseAdvice(
        "⚠ Low Glucose",
        "Take 15g fast sugar (juice/candy). Recheck after 15 minutes. If symptoms are severe, seek help.",
        "high",
      );
    }
    if (glucoseMgdl < 90) {
      return GlucoseAdvice(
        "Low-Normal",
        "Glucose is slightly low. Consider a light snack if you feel dizzy or weak.",
        "medium",
      );
    }
    if (glucoseMgdl <= 140) {
      return GlucoseAdvice(
        "✅ Normal",
        "Glucose is within normal range. Keep monitoring.",
        "normal",
      );
    }
    if (glucoseMgdl <= 180) {
      return GlucoseAdvice(
        "High Glucose",
        "Drink water. If safe, do a short walk. Avoid sugary foods now.",
        "medium",
      );
    }
    if (glucoseMgdl <= 250) {
      return GlucoseAdvice(
        "⚠ Very High",
        "Drink water, avoid carbs now, and monitor again soon. If you feel unwell, contact your doctor.",
        "high",
      );
    }
    return GlucoseAdvice(
      "🚨 Critical High",
      "Very high glucose. Drink water and contact your doctor if symptoms (vomiting, confusion, breathing issues).",
      "high",
    );
  }
}
