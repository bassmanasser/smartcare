class GlucoseAdvice {
  final String severity; // "normal" | "medium" | "high"
  final String message;

  const GlucoseAdvice({required this.severity, required this.message});
}

class GlucoseAdvisor {
  /// Call this from UI:
  /// final advice = GlucoseAdvisor.getAdvice(glucoseValue);
  static GlucoseAdvice getAdvice(double glucoseMgDl) {
    if (glucoseMgDl <= 0) {
      return const GlucoseAdvice(
        severity: "normal",
        message: "No glucose reading yet. Place your finger on the sensor for a few seconds.",
      );
    }

    // Safety: clamp weird values
    final g = glucoseMgDl.clamp(20.0, 600.0);

    // Hypoglycemia levels
    if (g < 54) {
      return const GlucoseAdvice(
        severity: "high",
        message:
            "Very low glucose. Take fast-acting sugar now and re-check in 15 minutes. Seek help if symptoms are severe.",
      );
    }
    if (g < 70) {
      return const GlucoseAdvice(
        severity: "high",
        message:
            "Low glucose. Take 15g fast-acting carbs and re-check in 15 minutes.",
      );
    }

    // Normal / target ranges (general guidance)
    // We don't know if fasting or after meal, so we provide context-based advice.
    if (g <= 99) {
      return const GlucoseAdvice(
        severity: "normal",
        message:
            "Looks normal (fasting range). If this was after a meal, it's excellent.",
      );
    }

    if (g <= 125) {
      return const GlucoseAdvice(
        severity: "medium",
        message:
            "Slightly elevated if fasting. If this was after a meal, it can still be acceptable. Consider re-checking later.",
      );
    }

    // Diabetes threshold (fasting) >=126
    if (g <= 140) {
      return const GlucoseAdvice(
        severity: "medium",
        message:
            "If fasting, this is high. If after a meal (1–2h), it may be near target. Drink water and re-check later.",
      );
    }

    // After-meal target often <180 (for many patients)
    if (g <= 180) {
      return const GlucoseAdvice(
        severity: "medium",
        message:
            "Moderately high. If this is 1–2 hours after a meal it may be acceptable for some, but re-check and follow your care plan.",
      );
    }

    // High
    if (g <= 250) {
      return const GlucoseAdvice(
        severity: "high",
        message:
            "High glucose. Hydrate, avoid sugary intake, and follow your care plan. Re-check soon.",
      );
    }

    // Very high
    return const GlucoseAdvice(
      severity: "high",
      message:
          "Very high glucose. Follow your emergency plan and consider contacting your doctor if it persists or if you feel unwell.",
    );
  }
}
