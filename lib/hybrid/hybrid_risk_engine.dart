import '../baseline/rule_based_baseline_engine.dart';
import '../core/enums/risk_enums.dart';
import '../data/models/daily_feature_snapshot.dart';
import '../derm/rule_based_derm_engine.dart';
import 'hybrid_risk_result.dart';

class HybridRiskEngine {
  const HybridRiskEngine({
    this.baselineEngine = const RuleBasedBaselineEngine(),
    this.dermEngine = const RuleBasedDermEngine(),
  });

  final RuleBasedBaselineEngine baselineEngine;
  final RuleBasedDermEngine dermEngine;

  Future<HybridRiskResult> evaluate({
    required List<DailyFeatureSnapshot> calibrationHistory,
    required List<DailyFeatureSnapshot> recentFeatures,
    required double userDailyLimitMinutes,
  }) async {
    // Step 1: Build personalization only from a designated calibration/history
    // window. The current evaluation window is intentionally kept separate to
    // avoid target leakage and accidental normalization of a deteriorating period.
    final baselineProfiles = await baselineEngine.evaluate(
      history: calibrationHistory,
      currentPeriodIsRisky: false,
    );

    // Step 2: DERM evaluates the current window against the prior baseline.
    final assessment = dermEngine.evaluate(
      recentFeatures: recentFeatures,
      baselineProfiles: baselineProfiles,
      userDailyLimitMinutes: userDailyLimitMinutes,
    );

    final currentPeriodIsRisky = assessment.riskLevel == RiskLevel.watch ||
        assessment.riskLevel == RiskLevel.elevated;

    final meanCompleteness = recentFeatures.isEmpty
        ? 0.0
        : recentFeatures
                .map((e) => e.dataCompleteness)
                .reduce((a, b) => a + b) /
            recentFeatures.length;

    final updateAllowed = baselineEngine.shouldUpdateBaseline(
      currentPeriodIsRisky: currentPeriodIsRisky,
      dataCompleteness: meanCompleteness,
    );

    // Step 3: Report FROZEN when the current period is risky. Existing stable
    // baseline values stay intact; this result tells persistence code not to
    // absorb the current period into the user's normal profile.
    final state = currentPeriodIsRisky
        ? BaselineState.frozen
        : baselineProfiles.isEmpty
            ? BaselineState.calibrating
            : baselineProfiles.first.state;

    return HybridRiskResult(
      assessment: assessment,
      baselineProfiles: baselineProfiles,
      baselineState: state,
      baselineUpdateAllowed: updateAllowed,
    );
  }
}
