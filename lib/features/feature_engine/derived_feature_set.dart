class DerivedFeatureSet {
  const DerivedFeatureSet({
    required this.threeDaySocialChange,
    required this.sevenDaySocialChange,
    required this.persistenceDays,
    required this.meanDataCompleteness,
  });

  /// Relative change, e.g. 0.25 means +25%.
  final double threeDaySocialChange;

  /// Relative change, e.g. 0.25 means +25%.
  final double sevenDaySocialChange;

  /// Consecutive recent days with at least one self-set limit exceedance.
  final int persistenceDays;

  /// Mean completeness of the evaluated window in [0, 1].
  final double meanDataCompleteness;
}
