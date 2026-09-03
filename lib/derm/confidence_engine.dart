import '../core/enums/risk_enums.dart';
import '../data/models/baseline_profile.dart';
import '../data/models/daily_feature_snapshot.dart';

class ConfidenceEngine {
  const ConfidenceEngine({
    this.insufficientDataCompleteness = 0.50,
    this.highDataCompleteness = 0.85,
    this.highBaselineConfidence = 0.70,
  });

  /// Provisional engineering settings. They are not clinical cut-offs and
  /// should be replaced/refined through pilot validation.
  final double insufficientDataCompleteness;
  final double highDataCompleteness;
  final double highBaselineConfidence;

  ConfidenceLevel evaluate({
    required List<DailyFeatureSnapshot> recentFeatures,
    required List<BaselineProfile> baselineProfiles,
  }) {
    if (recentFeatures.isEmpty) return ConfidenceLevel.insufficient;

    final completeness = recentFeatures
            .map((e) => e.dataCompleteness)
            .reduce((a, b) => a + b) /
        recentFeatures.length;

    if (completeness < insufficientDataCompleteness) {
      return ConfidenceLevel.insufficient;
    }

    if (baselineProfiles.isEmpty) {
      return completeness >= highDataCompleteness
          ? ConfidenceLevel.medium
          : ConfidenceLevel.low;
    }

    final baselineConfidence = baselineProfiles
            .map((e) => e.confidence)
            .reduce((a, b) => a + b) /
        baselineProfiles.length;

    if (completeness >= highDataCompleteness &&
        baselineConfidence >= highBaselineConfidence) {
      return ConfidenceLevel.high;
    }

    return ConfidenceLevel.medium;
  }
}
