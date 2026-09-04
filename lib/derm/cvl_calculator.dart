import '../data/models/daily_feature_snapshot.dart';

class CvlCalculator {
  const CvlCalculator();

  /// Contextual Vulnerability Level (CVL).
  ///
  /// Pilot v0.2 removes the arbitrary fixed "60 night minutes" reference.
  /// Instead, CVL is the share of observed screen time that occurred inside
  /// the configured sensitive/night window across the evaluation period:
  ///
  /// CVL = sum(night_usage_minutes) / sum(total_screen_time_minutes)
  ///
  /// This is a contextual exposure signal, not a clinical threshold. CVL
  /// alone cannot produce ELEVATED risk.
  double calculate(List<DailyFeatureSnapshot> recentFeatures) {
    if (recentFeatures.isEmpty) return 0;

    var totalScreen = 0.0;
    var totalNight = 0.0;

    for (final day in recentFeatures) {
      if (day.dataCompleteness <= 0) continue;
      totalScreen += day.totalScreenTimeMinutes;
      totalNight += day.nightUsageMinutes;
    }

    if (totalScreen <= 0) return 0;
    return (totalNight / totalScreen).clamp(0.0, 1.0).toDouble();
  }
}
