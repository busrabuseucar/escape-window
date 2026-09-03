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
}
