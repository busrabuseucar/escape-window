import 'dart:math' as math;

import '../core/enums/risk_enums.dart';
import '../data/models/baseline_profile.dart';
import '../data/models/daily_feature_snapshot.dart';
import 'baseline_engine.dart';

class RuleBasedBaselineEngine implements BaselineEngine {
  const RuleBasedBaselineEngine({
    this.minimumStableDays = 7,
    this.minimumCompleteness = 0.80,
  });

  final int minimumStableDays;
  final double minimumCompleteness;

  @override
  Future<List<BaselineProfile>> evaluate({
    required List<DailyFeatureSnapshot> history,
    required bool currentPeriodIsRisky,
  }) async {
    if (history.isEmpty) return const [];

    // Missing capture is not a day of zero use.
    final sorted = history.where((day) => day.dataCompleteness > 0).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.isEmpty) return const [];
    final meanCompleteness = sorted
            .map((day) => day.dataCompleteness)
            .reduce((a, b) => a + b) /
        sorted.length;

    final state = determineState(
      historyDays: sorted.length,
      meanCompleteness: meanCompleteness,
      currentPeriodIsRisky: currentPeriodIsRisky,
    );

    // A risky current period is represented as FROZEN. The caller should keep
    // the last known stable profile instead of silently learning this period as
    // the user's new normal. During first-time calibration there may be no prior
    // stable profile, so the returned values are descriptive only and must not
    // be treated as trusted personalization.
    final confidence = _baselineConfidence(
      days: sorted.length,
      completeness: meanCompleteness,
      state: state,
    );

    final updatedAt = sorted.last.date;

    return [
      _profile('total_screen_time', sorted.map((e) => e.totalScreenTimeMinutes).toList(), confidence, state, updatedAt),
      _profile('social_media_time', sorted.map((e) => e.socialMediaTimeMinutes).toList(), confidence, state, updatedAt),
      _profile('night_usage', sorted.map((e) => e.nightUsageMinutes).toList(), confidence, state, updatedAt),
      _profile('session_count', sorted.map((e) => e.sessionCount.toDouble()).toList(), confidence, state, updatedAt),
      _profile('mean_session_duration', sorted.map((e) => e.meanSessionDurationMinutes).toList(), confidence, state, updatedAt),
    ];
  }

  BaselineState determineState({
    required int historyDays,
    required double meanCompleteness,
    required bool currentPeriodIsRisky,
    bool recalibrationRequested = false,
  }) {
    if (currentPeriodIsRisky) return BaselineState.frozen;
    if (recalibrationRequested) return BaselineState.recalibrating;
    if (historyDays < minimumStableDays || meanCompleteness < minimumCompleteness) {
      return BaselineState.calibrating;
    }
    return BaselineState.stable;
  }

  @override
  bool shouldUpdateBaseline({
    required bool currentPeriodIsRisky,
    required double dataCompleteness,
  }) {
    return !currentPeriodIsRisky && dataCompleteness >= minimumCompleteness;
  }

  BaselineProfile _profile(
    String featureName,
    List<double> values,
    double confidence,
    BaselineState state,
    DateTime updatedAt,
  ) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.length < 2
        ? 0.0
        : values
                .map((value) => math.pow(value - mean, 2).toDouble())
                .reduce((a, b) => a + b) /
            values.length;

    return BaselineProfile(
      featureName: featureName,
      mean: mean,
      standardDeviation: math.sqrt(variance),
      confidence: confidence,
      state: state,
      updatedAt: updatedAt,
    );
  }

  double _baselineConfidence({
    required int days,
    required double completeness,
    required BaselineState state,
  }) {
    final dayConfidence = (days / minimumStableDays).clamp(0.0, 1.0);
    var confidence = dayConfidence * completeness.clamp(0.0, 1.0);

    if (state == BaselineState.frozen) {
      // Frozen means 'do not learn this period', not 'risk is certain'. Keep
      // confidence conservative until a previously stable profile is persisted.
      confidence *= 0.75;
    }
    if (state == BaselineState.recalibrating) confidence *= 0.60;

    return confidence.clamp(0.0, 1.0);
  }
}
