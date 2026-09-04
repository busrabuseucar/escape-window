import '../data/models/daily_feature_snapshot.dart';

class SrfiCalculator {
  const SrfiCalculator();

  /// Self-Regulation Failure Index (SRFI).
  ///
  /// Pilot v0.2 measures the *magnitude* of self-set limit violations rather
  /// than repeating BPI's persistence signal. For each measurable day:
  ///
  /// daily severity = exceedance_minutes / user_daily_limit_minutes
  ///
  /// The daily value is clamped to [0, 1], and SRFI is the mean across
  /// measurable days. This remains tied to the user's own goal and is not a
  /// clinical cut-off.
  double calculate(
    List<DailyFeatureSnapshot> recentFeatures, {
    required double userDailyLimitMinutes,
  }) {
    final measurable = recentFeatures
        .where((day) => day.dataCompleteness > 0)
        .toList(growable: false);

    if (measurable.isEmpty || userDailyLimitMinutes <= 0) return 0;

    final severitySum = measurable.fold<double>(0, (sum, day) {
      final dailySeverity =
          day.limitExceedanceMinutes / userDailyLimitMinutes;
      return sum + dailySeverity.clamp(0.0, 1.0).toDouble();
    });

    return (severitySum / measurable.length).clamp(0.0, 1.0).toDouble();
  }
}
