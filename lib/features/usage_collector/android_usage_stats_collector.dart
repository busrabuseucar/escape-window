import 'dart:io';

import 'package:flutter/services.dart';

import '../../data/models/daily_feature_snapshot.dart';
import 'usage_event_pairer.dart';
import 'usage_session_normalizer.dart';

class UsageAccessStatus {
  const UsageAccessStatus({required this.supported, required this.granted});

  final bool supported;
  final bool granted;
}

class AndroidUsageStatsCollector {
  const AndroidUsageStatsCollector({
    this.channel = const MethodChannel('escape_window_ai/usage_stats'),
    this.eventPairer = const UsageEventPairer(),
    this.sessionNormalizer = const UsageSessionNormalizer(),
  });

  final MethodChannel channel;
  final UsageEventPairer eventPairer;
  final UsageSessionNormalizer sessionNormalizer;

  Future<UsageAccessStatus> getAccessStatus() async {
    if (!Platform.isAndroid) {
      return const UsageAccessStatus(supported: false, granted: false);
    }
    final granted = await channel.invokeMethod<bool>('hasUsageAccess') ?? false;
    return UsageAccessStatus(supported: true, granted: granted);
  }

  Future<void> openUsageAccessSettings() async {
    if (!Platform.isAndroid) return;
    await channel.invokeMethod<void>('openUsageAccessSettings');
  }

  Future<DailyFeatureSnapshot> collectDay({
    required DateTime day,
    required double userDailyLimitMinutes,
    Set<String> trackedSocialPackages = const {},
    int sensitiveWindowStartHour = 22,
    int sensitiveWindowEndHour = 6,
  }) async {
    if (!Platform.isAndroid) {
      throw const UsageStatsUnavailableException(
        'Android UsageStats is not supported on this platform.',
      );
    }

    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    final raw = await channel.invokeListMethod<dynamic>('queryUsageEvents', {
          'startMs': start.millisecondsSinceEpoch,
          'endMs': end.millisecondsSinceEpoch,
        }) ??
        const [];

    final events = raw
        .whereType<Map>()
        .map((item) => UsageEventSample(
              packageName: item['packageName'] as String? ?? '',
              timestampMs: (item['timestampMs'] as num?)?.toInt() ?? 0,
              eventType: (item['eventType'] as num?)?.toInt() ?? -1,
            ))
        .where((e) => e.packageName.isNotEmpty && e.timestampMs > 0)
        .toList()
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

    final pairing = eventPairer.pairForDuration(
      events: events,
      dayEndMs: end.millisecondsSinceEpoch,
    );
    final durationSessions = pairing.sessions;

    double totalMinutes = 0;
    double socialMinutes = 0;
    double nightMinutes = 0;
    final trackedDurationSessions = <UsageSessionWindow>[];
    final trackedPackageMinutes = <String, double>{};

    for (final session in durationSessions) {
      final minutes = session.durationMinutes;
      totalMinutes += minutes;
      if (trackedSocialPackages.contains(session.packageName)) {
        socialMinutes += minutes;
        trackedDurationSessions.add(session);
        trackedPackageMinutes.update(
          session.packageName,
          (value) => value + minutes,
          ifAbsent: () => minutes,
        );
      }
      nightMinutes += _sensitiveOverlapMinutes(
        session,
        start,
        sensitiveWindowStartHour,
        sensitiveWindowEndHour,
      );
    }

    final interactionEpisodes =
        sessionNormalizer.mergeInteractionEpisodes(trackedDurationSessions);
    final sessionCount = interactionEpisodes.length;

    final limitExceedanceMinutes =
        (socialMinutes - userDailyLimitMinutes).clamp(0.0, double.infinity).toDouble();

    final trackedDuplicateForegroundCount = pairing.duplicateForegroundByPackage.entries
        .where((entry) => trackedSocialPackages.contains(entry.key))
        .fold<int>(0, (sum, entry) => sum + entry.value);

    return DailyFeatureSnapshot(
      date: start,
      totalScreenTimeMinutes: totalMinutes,
      socialMediaTimeMinutes: socialMinutes,
      nightUsageMinutes: nightMinutes,
      sessionCount: sessionCount,
      meanSessionDurationMinutes:
          sessionCount == 0 ? 0 : socialMinutes / sessionCount,
      limitExceedanceCount: limitExceedanceMinutes > 0 ? 1 : 0,
      limitExceedanceMinutes: limitExceedanceMinutes,
      dataCompleteness: events.isEmpty ? 0.0 : 1.0,
      rawEventCount: events.length,
      pairedIntervalCount: durationSessions.length,
      unmatchedForegroundCount: pairing.unmatchedForegroundCount,
      unmatchedBackgroundCount: pairing.unmatchedBackgroundCount,
      trackedRawIntervalCount: trackedDurationSessions.length,
      trackedPackageMinutes: Map.unmodifiable(trackedPackageMinutes),
      legacyTotalScreenTimeMinutes: totalMinutes,
      legacySocialMediaTimeMinutes: socialMinutes,
      legacyTrackedIntervalCount: trackedDurationSessions.length,
      legacyTrackedPackageMinutes: Map.unmodifiable(trackedPackageMinutes),
      duplicateForegroundCount: pairing.duplicateForegroundCount,
      trackedDuplicateForegroundCount: trackedDuplicateForegroundCount,
      duplicateForegroundByPackage: pairing.duplicateForegroundByPackage,
    );
  }

  double _sensitiveOverlapMinutes(
    UsageSessionWindow session,
    DateTime dayStart,
    int startHour,
    int endHour,
  ) {
    final sessionStart = DateTime.fromMillisecondsSinceEpoch(session.startMs);
    final sessionEnd = DateTime.fromMillisecondsSinceEpoch(session.endMs);
    final windows = <({DateTime start, DateTime end})>[];
    if (startHour > endHour) {
      windows.add((start: dayStart, end: DateTime(dayStart.year, dayStart.month, dayStart.day, endHour)));
      windows.add((
        start: DateTime(dayStart.year, dayStart.month, dayStart.day, startHour),
        end: DateTime(dayStart.year, dayStart.month, dayStart.day + 1),
      ));
    } else {
      windows.add((
        start: DateTime(dayStart.year, dayStart.month, dayStart.day, startHour),
        end: DateTime(dayStart.year, dayStart.month, dayStart.day, endHour),
      ));
    }
    double minutes = 0;
    for (final window in windows) {
      final overlapStart = sessionStart.isAfter(window.start) ? sessionStart : window.start;
      final overlapEnd = sessionEnd.isBefore(window.end) ? sessionEnd : window.end;
      if (overlapEnd.isAfter(overlapStart)) {
        minutes += overlapEnd.difference(overlapStart).inSeconds / 60.0;
      }
    }
    return minutes;
  }
}

class UsageStatsUnavailableException implements Exception {
  const UsageStatsUnavailableException(this.message);
  final String message;

  @override
  String toString() => message;
}
