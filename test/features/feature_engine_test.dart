import 'package:flutter_test/flutter_test.dart';
import 'package:escape_window_ai/features/feature_engine/feature_engine.dart';
import 'package:escape_window_ai/features/usage_collector/demo_data_provider.dart';

void main() {
  const engine = FeatureEngine();
  const demo = DemoDataProvider();

  test('persistent-risk scenario exposes consecutive limit violations', () {
    final derived = engine.derive(demo.persistentRiskScenario());

    expect(derived.persistenceDays, 5);
    expect(derived.meanDataCompleteness, 1.0);
  });

  test('normal scenario has no persistent limit violation', () {
    final derived = engine.derive(demo.normalScenario());

    expect(derived.persistenceDays, 0);
  });
}
