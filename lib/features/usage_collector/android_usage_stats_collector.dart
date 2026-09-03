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

  /// Converts Android UsageEvents into the privacy-minimized daily feature
  /// snapshot consumed by DERM. No message/content data is requested.
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

    for (final event in events) {
      if (event.eventType == 1) {
        // UsageEvents.Event.MOVE_TO_FOREGROUND. A duplicate foreground event
        // for an already-active package must not reset the start timestamp;
        // doing so fragments one interaction episode into many tiny sessions.
        foregroundStartedAt.putIfAbsent(event.packageName, () => event.timestampMs);
      } else if (event.eventType == 2) {
        // UsageEvents.Event.MOVE_TO_BACKGROUND
        final startedAt = foregroundStartedAt.remove(event.packageName);
        if (startedAt != null && event.timestampMs > startedAt) {
          sessions.add(UsageSessionWindow(
            packageName: event.packageName,
            startMs: startedAt,
            endMs: event.timestampMs,
          ));
        }
      }
    }

    // Close sessions still in foreground at the end of the requested day.
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

    for (final session in sessions) {
      final minutes = session.durationMinutes;
      totalMinutes += minutes;

      if (trackedSocialPackages.contains(session.packageName)) {
        socialMinutes += minutes;
        trackedSessions.add(session);
      }

      nightMinutes += _sensitiveOverlapMinutes(
        session,
        start,
        sensitiveWindowStartHour,
        sensitiveWindowEndHour,
      );
    }

    final limitExceedanceMinutes =
        (socialMinutes - userDailyLimitMinutes).clamp(0.0, double.infinity).toDouble();

    // A user-facing "session" is an interaction episode, not every raw Android
    // foreground/background transition. Same-package intervals separated by at
    // most 30 seconds are merged to absorb short internal Activity transitions
    // and transient interruptions. Screen/social/night totals above remain
    // based on raw intervals, so this correction does not alter risk inputs.
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
