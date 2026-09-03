class PbdCalculator {
  const PbdCalculator({this.epsilon = 1e-6});

  final double epsilon;

  /// Calculates standardized deviation from the user's personal baseline.
  /// PBD is a calibration signal, not an independent clinical risk score.
  double calculate({
    required double currentValue,
    required double baselineMean,
    required double baselineStandardDeviation,
  }) {
    final denominator = baselineStandardDeviation.abs() + epsilon;
    return (currentValue - baselineMean) / denominator;
  }
}
