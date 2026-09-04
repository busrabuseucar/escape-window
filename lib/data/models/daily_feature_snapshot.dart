class DailyFeatureSnapshot {
  const DailyFeatureSnapshot({
    required this.date,
    required this.totalScreenTimeMinutes,
    required this.socialMediaTimeMinutes,
    required this.nightUsageMinutes,
    required this.sessionCount,
    required this.meanSessionDurationMinutes,
    required this.limitExceedanceCount,
    required this.limitExceedanceMinutes,
    required this.dataCompleteness,
    this.rawEventCount = 0,
    this.pairedIntervalCount = 0,
    this.unmatchedForegroundCount = 0,
    this.unmatchedBackgroundCount = 0,
    this.trackedRawIntervalCount = 0,
    this.trackedPackageMinutes = const {},
    this.legacyTotalScreenTimeMinutes = 0,
    this.legacySocialMediaTimeMinutes = 0,
    this.legacyTrackedIntervalCount = 0,
    this.legacyTrackedPackageMinutes = const {},
    this.duplicateForegroundCount = 0,
    this.trackedDuplicateForegroundCount = 0,
    this.duplicateForegroundByPackage = const {},
  });

  final DateTime date;
  final double totalScreenTimeMinutes;
  final double socialMediaTimeMinutes;
  final double nightUsageMinutes;
  final int sessionCount;
  final double meanSessionDurationMinutes;
  final int limitExceedanceCount;
  final double limitExceedanceMinutes;

  /// Normalized to the range [0, 1].
  final double dataCompleteness;

  /// Engineering diagnostics for physical-device UsageStats validation.
  /// These fields are observational only and are not DERM risk inputs.
  final int rawEventCount;
  final int pairedIntervalCount;
  final int unmatchedForegroundCount;
  final int unmatchedBackgroundCount;
  final int trackedRawIntervalCount;
  final Map<String, double> trackedPackageMinutes;

  /// Counterfactual metrics calculated from the exact same raw event list
  /// using the pre-fix pairing rule where every foreground event overwrites
  /// the package start timestamp. These are diagnostics only.
  final double legacyTotalScreenTimeMinutes;
  final double legacySocialMediaTimeMinutes;
  final int legacyTrackedIntervalCount;
  final Map<String, double> legacyTrackedPackageMinutes;

  /// Foreground events received while the same package is already marked as
  /// foreground. These events are the exact condition where legacy and fixed
  /// pairing semantics can diverge.
  final int duplicateForegroundCount;
  final int trackedDuplicateForegroundCount;
  final Map<String, int> duplicateForegroundByPackage;
}
