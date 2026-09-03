import 'package:flutter_test/flutter_test.dart';
import 'package:escape_window_ai/core/enums/risk_enums.dart';
import 'package:escape_window_ai/derm/rule_based_derm_engine.dart';
import 'package:escape_window_ai/features/usage_collector/demo_data_provider.dart';

void main() {
  const engine = RuleBasedDermEngine();
  const demo = DemoDataProvider();

  test('normal scenario stays LOW', () {
    final result = engine.evaluate(
      recentFeatures: demo.normalScenario(),
      baselineProfiles: const [],
      userDailyLimitMinutes: 120,
    );

    expect(result.riskLevel, RiskLevel.low);
    expect(result.safetyFlag, isFalse);
  });

  test('persistent repeated limit violations become ELEVATED', () {
    final result = engine.evaluate(
      recentFeatures: demo.persistentRiskScenario(),
      baselineProfiles: const [],
      userDailyLimitMinutes: 120,
    );

    expect(result.riskLevel, RiskLevel.elevated);
    expect(result.drivers, contains(RiskDriver.behavioralPersistence));
    expect(result.drivers, contains(RiskDriver.selfRegulationFailure));
    expect(result.safetyFlag, isTrue);
    expect(result.explanation, isNotEmpty);
  });
}
