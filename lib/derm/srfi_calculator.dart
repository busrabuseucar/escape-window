import '../data/models/daily_feature_snapshot.dart';

class SrfiCalculator {
  const SrfiCalculator();

  /// Self-Regulation Failure Index.
  /// Ratio of observed self-set limit violations to measurable days.
  ///
  /// This is intentionally tied to the user's own goal and is not a clinical
  /// threshold. Values are normalized to [0, 1].
  double calculate(List<DailyFeatureSnapshot> recentFeatures) {
    final measurable = recentFeatures
        .where((day) => day.dataCompleteness > 0)
        .toList(growable: false);
    if (measurable.isEmpty) return 0;

    final violationDays = measurable
        .where((day) => day.limitExceedanceCount > 0)
        .length;

    return violationDays / measurable.length;
  }
}
