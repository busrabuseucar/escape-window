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
}
