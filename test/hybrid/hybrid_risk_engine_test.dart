import 'package:escape_window_ai/core/enums/risk_enums.dart';
import 'package:escape_window_ai/features/usage_collector/demo_data_provider.dart';
import 'package:escape_window_ai/hybrid/hybrid_risk_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = HybridRiskEngine();
  const demo = DemoDataProvider();

  test('normal recent period keeps baseline stable and updateable', () async {
    final calibration = demo.normalScenario();
    final result = await engine.evaluate(
      calibrationHistory: calibration,
      recentFeatures: calibration,
      userDailyLimitMinutes: 120,
    );

    expect(result.baselineState, BaselineState.stable);
    expect(result.baselineUpdateAllowed, isTrue);
    expect(result.assessment.riskLevel, RiskLevel.low);
  });

  test('persistent risky period freezes baseline and blocks learning', () async {
    final result = await engine.evaluate(
      calibrationHistory: demo.normalScenario(),
      recentFeatures: demo.persistentRiskScenario(),
      userDailyLimitMinutes: 120,
    );

    expect(result.assessment.riskLevel, RiskLevel.elevated);
    expect(result.baselineState, BaselineState.frozen);
    expect(result.baselineUpdateAllowed, isFalse);
    expect(result.assessment.pbd, greaterThan(0));
  });

  test('insufficient calibration cannot masquerade as stable baseline', () async {
    final shortCalibration = demo.normalScenario().take(3).toList();
    final result = await engine.evaluate(
      calibrationHistory: shortCalibration,
      recentFeatures: demo.persistentRiskScenario(),
      userDailyLimitMinutes: 120,
    );

    expect(
      result.baselineProfiles.every((p) => p.state == BaselineState.calibrating),
      isTrue,
    );
    expect(result.assessment.safetyFlag, isTrue);
  });
}
