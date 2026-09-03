import 'dart:io';

import 'package:flutter/services.dart';

import '../../data/models/daily_feature_snapshot.dart';
import 'usage_session_normalizer.dart';

class UsageAccessStatus {
  const UsageAccessStatus({required this.supported, required this.granted});

  final bool supported;
  final bool granted;
}

class AndroidUsageStatsCollector {
  const AndroidUsageStatsCollector({
    this.channel = const MethodChannel('escape_window_ai/usage_stats'),
    this.sessionNormalizer = const UsageSessionNormalizer(),
  });

  final MethodChannel channel;
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
    final end = start.add(const Duration(days: 1));
    final raw = await channel.invokeListMethod<dynamic>('queryUsageEvents', {
          'startMs': start.millisecondsSinceEpoch,
          'endMs': end.millisecondsSinceEpoch,
        }) ??
        const [];

    final events = raw
        .whereType<Map>()
        .map((item) => _UsageEvent(
              packageName: item['packageName'] as String? ?? '',
              timestampMs: (item['timestampMs'] as num?)?.toInt() ?? 0,
              eventType: (item['eventType'] as num?)?.toInt() ?? -1,
            ))
        .where((e) => e.packageName.isNotEmpty && e.timestampMs > 0)
        .toList()
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

    // Duration pairing deliberately keeps the most recent foreground timestamp
    // for a package. Physical-device diagnostics showed that preserving the
    // earliest duplicate foreground can substantially over-count Instagram
    // duration on some days. This pairing is therefore used for all duration
    // metrics and risk inputs.
    final durationStarts = <String, int>{};
    final durationSessions = <UsageSessionWindow>[];
    final duplicateForegroundByPackage = <String, int>{};
    var duplicateForegroundCount = 0;
    var trackedDuplicateForegroundCount = 0;
    var unmatchedBackgroundCount = 0;

    for (final event in events) {
      if (event.eventType == 1) {
        if (durationStarts.containsKey(event.packageName)) {
          duplicateForegroundCount++;
          duplicateForegroundByPackage.update(
            event.packageName,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
          if (trackedSocialPackages.contains(event.packageName)) {
            trackedDuplicateForegroundCount++;
          }
        }
        durationStarts[event.packageName] = event.timestampMs;
      } else if (event.eventType == 2) {
        final startedAt = durationStarts.remove(event.packageName);
        if (startedAt != null && event.timestampMs > startedAt) {
          durationSessions.add(UsageSessionWindow(
            packageName: event.packageName,
            startMs: startedAt,
            endMs: event.timestampMs,
          ));
        } else if (startedAt == null) {
          unmatchedBackgroundCount++;
        }
      }
    }

    final unmatchedForegroundCount = durationStarts.length;
    for (final entry in durationStarts.entries) {
      if (end.millisecondsSinceEpoch > entry.value) {
        durationSessions.add(UsageSessionWindow(
          packageName: entry.key,
          startMs: entry.value,
          endMs: end.millisecondsSinceEpoch,
        ));
      }
    }

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

    // Session count is a separate user-facing behavioral metric. It is derived
    // from the duration-paired tracked intervals, then normalized so short
    // same-package interruptions (<=30 s) do not inflate one interaction into
    // many sessions. This normalization does not change duration/risk inputs.
    final interactionEpisodes =
        sessionNormalizer.mergeInteractionEpisodes(trackedDurationSessions);
    final sessionCount = interactionEpisodes.length;

    final limitExceedanceMinutes =
        (socialMinutes - userDailyLimitMinutes).clamp(0.0, double.infinity).toDouble();

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
      unmatchedForegroundCount: unmatchedForegroundCount,
      unmatchedBackgroundCount: unmatchedBackgroundCount,
      trackedRawIntervalCount: trackedDurationSessions.length,
      trackedPackageMinutes: Map.unmodifiable(trackedPackageMinutes),
      legacyTotalScreenTimeMinutes: totalMinutes,
      legacySocialMediaTimeMinutes: socialMinutes,
      legacyTrackedIntervalCount: trackedDurationSessions.length,
      legacyTrackedPackageMinutes: Map.unmodifiable(trackedPackageMinutes),
      duplicateForegroundCount: duplicateForegroundCount,
      trackedDuplicateForegroundCount: trackedDuplicateForegroundCount,
      duplicateForegroundByPackage: Map.unmodifiable(duplicateForegroundByPackage),
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
      windows.add((start: dayStart, end: dayStart.add(Duration(hours: endHour))));
      windows.add((
        start: dayStart.add(Duration(hours: startHour)),
        end: dayStart.add(const Duration(days: 1)),
      ));
    } else {
      windows.add((
        start: dayStart.add(Duration(hours: startHour)),
        end: dayStart.add(Duration(hours: endHour)),
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

class _UsageEvent {
  const _UsageEvent({
    required this.packageName,
    required this.timestampMs,
    required this.eventType,
  });

  final String packageName;
  final int timestampMs;
  final int eventType;
}
