import 'package:escape_window_ai/baseline/pbd_calculator.dart';
import 'package:escape_window_ai/core/enums/risk_enums.dart';
import 'package:escape_window_ai/data/models/baseline_profile.dart';
import 'package:escape_window_ai/data/models/daily_feature_snapshot.dart';
import 'package:escape_window_ai/derm/bpi_calculator.dart';
import 'package:escape_window_ai/derm/cvl_calculator.dart';
import 'package:escape_window_ai/derm/rule_based_derm_engine.dart';
import 'package:escape_window_ai/derm/srfi_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

DailyFeatureSnapshot day({
  required int index,
  double total = 240,
  double social = 120,
  double night = 0,
  double exceed = 0,
  double completeness = 1,
}) {
  return DailyFeatureSnapshot(
    date: DateTime(2026, 9, 1 + index),
    totalScreenTimeMinutes: total,
    socialMediaTimeMinutes: social,
    nightUsageMinutes: night,
    sessionCount: 10,
    meanSessionDurationMinutes: 12,
    limitExceedanceCount: exceed > 0 ? 1 : 0,
    limitExceedanceMinutes: exceed,
    dataCompleteness: completeness,
  );
}

BaselineProfile socialBaseline({
  double mean = 100,
  double sd = 20,
  double confidence = 0.9,
}) {
  return BaselineProfile(
    featureName: 'social_media_time',
    mean: mean,
    standardDeviation: sd,
    confidence: confidence,
    state: BaselineState.stable,
    updatedAt: DateTime(2026, 8, 31),
  );
}

void main() {
  group('DERM v0.2 pilot component semantics', () {
    test('BPI rewards repeated and consecutive violations', () {
      const calculator = BpiCalculator();
      final result = calculator.calculate([
        day(index: 0, exceed: 10),
        day(index: 1, exceed: 10),
        day(index: 2),
        day(index: 3, exceed: 10),
      ]);

      // 3/4 violation fraction and 2/4 longest streak.
      expect(result, closeTo(0.625, 1e-9));
    });

    test('SRFI measures exceedance magnitude relative to self-set limit', () {
      const calculator = SrfiCalculator();
      final result = calculator.calculate(
        [
          day(index: 0, exceed: 60),
          day(index: 1, exceed: 0),
          day(index: 2, exceed: 120),
        ],
        userDailyLimitMinutes: 120,
      );

      // (0.5 + 0 + 1.0) / 3
      expect(result, closeTo(0.5, 1e-9));
    });

    test('CVL is the share of total screen time occurring at night', () {
      const calculator = CvlCalculator();
      final result = calculator.calculate([
        day(index: 0, total: 200, night: 50),
        day(index: 1, total: 300, night: 50),
      ]);

      expect(result, closeTo(0.2, 1e-9));
    });

    test('PBD keeps only positive deviation and caps extreme z scores', () {
      const calculator = PbdCalculator();
      expect(
        calculator.calculate(
          currentValue: 80,
          baselineMean: 100,
          baselineStandardDeviation: 10,
        ),
        0,
      );
      expect(
        calculator.calculate(
          currentValue: 200,
          baselineMean: 100,
          baselineStandardDeviation: 1,
        ),
        3,
      );
    });
  });

  group('DERM v0.2 pilot risk gates', () {
    const engine = RuleBasedDermEngine();

    test('PBD alone never raises core risk level', () {
      final assessment = engine.evaluate(
        recentFeatures: [
          for (var i = 0; i < 7; i++)
            day(index: i, social: 180, total: 300, night: 0, exceed: 0),
        ],
        baselineProfiles: [socialBaseline(mean: 100, sd: 10)],
        userDailyLimitMinutes: 240,
      );

      expect(assessment.pbd, greaterThanOrEqualTo(1));
      expect(assessment.riskLevel, RiskLevel.low);
      expect(assessment.drivers, contains(RiskDriver.personalDeviation));
      expect(assessment.dermVersion, 'derm-rule-v0.2.0-pilot');
    });

    test('two independent elevated core signals produce elevated risk', () {
      final assessment = engine.evaluate(
        recentFeatures: [
          for (var i = 0; i < 7; i++)
            day(index: i, social: 360, total: 400, night: 20, exceed: 240),
        ],
        baselineProfiles: [socialBaseline()],
        userDailyLimitMinutes: 120,
      );

      expect(assessment.bpi, greaterThanOrEqualTo(0.65));
      expect(assessment.srfi, greaterThanOrEqualTo(0.65));
      expect(assessment.riskLevel, RiskLevel.elevated);
    });

    test('a contextual signal alone can trigger watch but not elevated', () {
      final assessment = engine.evaluate(
        recentFeatures: [
          for (var i = 0; i < 7; i++)
            day(index: i, total: 100, social: 50, night: 70, exceed: 0),
        ],
        baselineProfiles: [socialBaseline()],
        userDailyLimitMinutes: 120,
      );

      expect(assessment.cvl, greaterThanOrEqualTo(0.65));
      expect(assessment.riskLevel, RiskLevel.watch);
    });
  });
}
