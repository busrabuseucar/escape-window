class PbdCalculator {
  const PbdCalculator({
    this.epsilon = 1e-6,
    this.maximumPositiveDeviation = 3.0,
  });

  final double epsilon;
  final double maximumPositiveDeviation;

  /// Positive standardized deviation from the user's personal baseline.
  ///
  /// PBD is a calibration/explanation signal, not an independent risk score.
  /// Negative deviations are mapped to zero because the pilot question is
  /// whether recent usage moved above the personal reference. Extreme values
  /// are capped so near-zero baseline variance cannot dominate explanations.
  double calculate({
    required double currentValue,
    required double baselineMean,
    required double baselineStandardDeviation,
  }) {
    final denominator = baselineStandardDeviation.abs() + epsilon;
    final z = (currentValue - baselineMean) / denominator;
    return z.clamp(0.0, maximumPositiveDeviation).toDouble();
  }
}
