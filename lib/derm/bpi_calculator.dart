import '../data/models/daily_feature_snapshot.dart';

class BpiCalculator {
  const BpiCalculator();

  /// Behavioral Persistence Index.
  /// Returns the fraction of evaluated recent days in which a risk condition
  /// (currently: at least one self-set limit exceedance) was observed.
  ///
  /// This is an MVP engineering definition, not a validated clinical metric.
  double calculate(List<DailyFeatureSnapshot> recentFeatures) {
    if (recentFeatures.isEmpty) return 0;

    final riskyDays = recentFeatures
        .where((day) => day.limitExceedanceCount > 0)
        .length;

    return riskyDays / recentFeatures.length;
  }
}
