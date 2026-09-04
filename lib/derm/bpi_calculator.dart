import '../data/models/daily_feature_snapshot.dart';

class BpiCalculator {
  const BpiCalculator();

  /// Behavioral Persistence Index (BPI).
  ///
  /// Pilot v0.2 separates persistence from self-regulation severity.
  /// Persistence combines:
  /// - the fraction of measurable days with a self-set limit violation, and
  /// - the longest consecutive violation streak in the evaluation window.
  ///
  /// BPI = 0.5 * violation_day_fraction + 0.5 * longest_streak_fraction
  ///
  /// This is a provisional engineering definition for pilot validation, not a
  /// clinical threshold or diagnostic metric.
  double calculate(List<DailyFeatureSnapshot> recentFeatures) {
    final measurable = recentFeatures
        .where((day) => day.dataCompleteness > 0)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (measurable.isEmpty) return 0;

    var violationDays = 0;
    var currentStreak = 0;
    var longestStreak = 0;

    for (final day in measurable) {
      if (day.limitExceedanceCount > 0) {
        violationDays++;
        currentStreak++;
        if (currentStreak > longestStreak) longestStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    }

    final n = measurable.length.toDouble();
    final violationFraction = violationDays / n;
    final streakFraction = longestStreak / n;

    return (0.5 * violationFraction + 0.5 * streakFraction)
        .clamp(0.0, 1.0)
        .toDouble();
  }
}
