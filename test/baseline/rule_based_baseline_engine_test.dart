import 'package:escape_window_ai/core/enums/risk_enums.dart';
import 'package:escape_window_ai/baseline/rule_based_baseline_engine.dart';
import 'package:escape_window_ai/features/usage_collector/demo_data_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = RuleBasedBaselineEngine();
  const demo = DemoDataProvider();

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
