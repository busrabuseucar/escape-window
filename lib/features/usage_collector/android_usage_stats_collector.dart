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

    final foregroundStartedAt = <String, int>{};
    final sessions = <UsageSessionWindow>[];
    var unmatchedBackgroundCount = 0;

    for (final event in events) {
      if (event.eventType == 1) {
        foregroundStartedAt.putIfAbsent(event.packageName, () => event.timestampMs);
      } else if (event.eventType == 2) {
        final startedAt = foregroundStartedAt.remove(event.packageName);
        if (startedAt != null && event.timestampMs > startedAt) {
          sessions.add(UsageSessionWindow(
            packageName: event.packageName,
            startMs: startedAt,
            endMs: event.timestampMs,
          ));
        } else if (startedAt == null) {
          unmatchedBackgroundCount++;
        }
      }
    }

    final unmatchedForegroundCount = foregroundStartedAt.length;
    for (final entry in foregroundStartedAt.entries) {
      if (end.millisecondsSinceEpoch > entry.value) {
        sessions.add(UsageSessionWindow(
          packageName: entry.key,
          startMs: entry.value,
          endMs: end.millisecondsSinceEpoch,
        ));
      }
    }

    double totalMinutes = 0;
    double socialMinutes = 0;
    double nightMinutes = 0;
    final trackedSessions = <UsageSessionWindow>[];
    final trackedPackageMinutes = <String, double>{};

    for (final session in sessions) {
      final minutes = session.durationMinutes;
      totalMinutes += minutes;
      if (trackedSocialPackages.contains(session.packageName)) {
        socialMinutes += minutes;
        trackedSessions.add(session);
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

    // Counterfactual: replay the exact same sorted raw events using the original
    // pre-fix rule. Repeated foreground events overwrite the package start.
    // This lets a physical-device test isolate pairing logic from Android event
    // retention/query variability.
    final legacyStarts = <String, int>{};
    final legacySessions = <UsageSessionWindow>[];
    for (final event in events) {
      if (event.eventType == 1) {
        legacyStarts[event.packageName] = event.timestampMs;
      } else if (event.eventType == 2) {
        final startedAt = legacyStarts.remove(event.packageName);
        if (startedAt != null && event.timestampMs > startedAt) {
          legacySessions.add(UsageSessionWindow(
            packageName: event.packageName,
            startMs: startedAt,
            endMs: event.timestampMs,
          ));
        }
      }
    }
    for (final entry in legacyStarts.entries) {
      if (end.millisecondsSinceEpoch > entry.value) {
        legacySessions.add(UsageSessionWindow(
          packageName: entry.key,
          startMs: entry.value,
          endMs: end.millisecondsSinceEpoch,
        ));
      }
    }

    var legacyTotalMinutes = 0.0;
    var legacySocialMinutes = 0.0;
    var legacyTrackedIntervals = 0;
    for (final session in legacySessions) {
      final minutes = session.durationMinutes;
      legacyTotalMinutes += minutes;
      if (trackedSocialPackages.contains(session.packageName)) {
        legacySocialMinutes += minutes;
        legacyTrackedIntervals++;
      }
    }

    final limitExceedanceMinutes =
        (socialMinutes - userDailyLimitMinutes).clamp(0.0, double.infinity).toDouble();
    final interactionEpisodes =
        sessionNormalizer.mergeInteractionEpisodes(trackedSessions);
    final sessionCount = interactionEpisodes.length;

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
      pairedIntervalCount: sessions.length,
      unmatchedForegroundCount: unmatchedForegroundCount,
      unmatchedBackgroundCount: unmatchedBackgroundCount,
      trackedRawIntervalCount: trackedSessions.length,
      trackedPackageMinutes: Map.unmodifiable(trackedPackageMinutes),
      legacyTotalScreenTimeMinutes: legacyTotalMinutes,
      legacySocialMediaTimeMinutes: legacySocialMinutes,
      legacyTrackedIntervalCount: legacyTrackedIntervals,
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
