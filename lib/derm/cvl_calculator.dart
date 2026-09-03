import '../data/models/daily_feature_snapshot.dart';

class CvlCalculator {
  const CvlCalculator({this.referenceNightMinutes = 60});

  /// Contextual Vulnerability Level.
  ///
  /// MVP proxy: mean night-usage intensity normalized against an engineering
  /// reference value. This reference is configurable and must not be presented
  /// as a clinical threshold. CVL alone never determines the final risk level.
  final double referenceNightMinutes;

  double calculate(List<DailyFeatureSnapshot> recentFeatures) {
    if (recentFeatures.isEmpty || referenceNightMinutes <= 0) return 0;

    final meanNight = recentFeatures
            .map((day) => day.nightUsageMinutes)
            .reduce((a, b) => a + b) /
        recentFeatures.length;

    return (meanNight / referenceNightMinutes).clamp(0.0, 1.0);
  }
}
