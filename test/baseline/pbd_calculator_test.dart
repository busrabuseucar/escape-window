import 'package:flutter_test/flutter_test.dart';
import 'package:escape_window_ai/baseline/pbd_calculator.dart';

void main() {
  group('PbdCalculator', () {
    test('returns positive deviation when current value exceeds baseline', () {
      const calculator = PbdCalculator();
      final result = calculator.calculate(
        currentValue: 140,
        baselineMean: 100,
        baselineStandardDeviation: 20,
      );

      expect(result, closeTo(2.0, 0.001));
    });

    test('remains finite when baseline standard deviation is zero', () {
      const calculator = PbdCalculator();
      final result = calculator.calculate(
        currentValue: 100,
        baselineMean: 100,
        baselineStandardDeviation: 0,
      );

      expect(result.isFinite, isTrue);
      expect(result, 0);
    });
  });
}
