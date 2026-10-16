import 'package:escape_window_ai/core/enums/risk_enums.dart';
import 'package:escape_window_ai/baseline/rule_based_baseline_engine.dart';
import 'package:escape_window_ai/features/usage_collector/demo_data_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:escape_window_ai/data/models/daily_feature_snapshot.dart';

void main() {
  const engine = RuleBasedBaselineEngine();
  const demo = DemoDataProvider();

  test('missing days do not lower baseline mean or count as calibration', () async {
    final missing = DailyFeatureSnapshot(date: DateTime(2026, 8, 1), totalScreenTimeMinutes: 0,
      socialMediaTimeMinutes: 0, nightUsageMinutes: 0, sessionCount: 0, meanSessionDurationMinutes: 0,
      limitExceedanceCount: 0, limitExceedanceMinutes: 0, dataCompleteness: 0);
    final measured = demo.normalScenario().first;
    final profiles = await engine.evaluate(history: [measured, ...List.filled(6, missing)], currentPeriodIsRisky: false);
    expect(profiles.firstWhere((p) => p.featureName == 'social_media_time').mean, measured.socialMediaTimeMinutes);
    expect(profiles.every((p) => p.state == BaselineState.calibrating), isTrue);
    expect(await engine.evaluate(history: [missing], currentPeriodIsRisky: false), isEmpty);
  });

  test('seven complete non-risky days produce a stable baseline', () async {
    final profiles = await engine.evaluate(
      history: demo.normalScenario(),
      currentPeriodIsRisky: false,
    );

    expect(profiles, isNotEmpty);
    expect(profiles.every((p) => p.state == BaselineState.stable), isTrue);
    expect(profiles.every((p) => p.confidence >= 0.8), isTrue);
  });

  test('risky period freezes baseline', () async {
    final profiles = await engine.evaluate(
      history: demo.persistentRiskScenario(),
      currentPeriodIsRisky: true,
    );

    expect(profiles.every((p) => p.state == BaselineState.frozen), isTrue);
    expect(
      engine.shouldUpdateBaseline(
        currentPeriodIsRisky: true,
        dataCompleteness: 1.0,
      ),
      isFalse,
    );
  });

  test('insufficient history stays calibrating', () {
    final state = engine.determineState(
      historyDays: 3,
      meanCompleteness: 1.0,
      currentPeriodIsRisky: false,
    );

    expect(state, BaselineState.calibrating);
  });

  test('low completeness blocks baseline update', () {
    expect(
      engine.shouldUpdateBaseline(
        currentPeriodIsRisky: false,
        dataCompleteness: 0.50,
      ),
      isFalse,
    );
  });

  test('explicit safe recalibration request enters recalibrating state', () {
    final state = engine.determineState(
      historyDays: 14,
      meanCompleteness: 1.0,
      currentPeriodIsRisky: false,
      recalibrationRequested: true,
    );

    expect(state, BaselineState.recalibrating);
  });
}
