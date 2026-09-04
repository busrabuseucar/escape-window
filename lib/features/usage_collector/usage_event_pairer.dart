import 'usage_session_normalizer.dart';

class UsageEventSample {
  const UsageEventSample({
    required this.packageName,
    required this.timestampMs,
    required this.eventType,
  });

  final String packageName;
  final int timestampMs;
  final int eventType;
}

class UsagePairingResult {
  const UsagePairingResult({
    required this.sessions,
    required this.unmatchedForegroundCount,
    required this.unmatchedBackgroundCount,
    required this.duplicateForegroundCount,
    required this.duplicateForegroundByPackage,
  });

  final List<UsageSessionWindow> sessions;
  final int unmatchedForegroundCount;
  final int unmatchedBackgroundCount;
  final int duplicateForegroundCount;
  final Map<String, int> duplicateForegroundByPackage;
}

class UsageEventPairer {
  const UsageEventPairer();

  UsagePairingResult pairForDuration({
    required List<UsageEventSample> events,
    required int dayEndMs,
  }) {
    final starts = <String, int>{};
    final sessions = <UsageSessionWindow>[];
    final duplicateByPackage = <String, int>{};
    var duplicateCount = 0;
    var unmatchedBackgroundCount = 0;

    for (final event in events) {
      if (event.eventType == 1) {
        if (starts.containsKey(event.packageName)) {
          duplicateCount++;
          duplicateByPackage.update(
            event.packageName,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }

        // Duration semantics intentionally use the most recent foreground
        // timestamp. Physical-device regression tests showed that keeping the
        // earliest duplicate foreground can substantially over-count duration.
        starts[event.packageName] = event.timestampMs;
      } else if (event.eventType == 2) {
        final startedAt = starts.remove(event.packageName);
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

    final unmatchedForegroundCount = starts.length;
    for (final entry in starts.entries) {
      if (dayEndMs > entry.value) {
        sessions.add(UsageSessionWindow(
          packageName: entry.key,
          startMs: entry.value,
          endMs: dayEndMs,
        ));
      }
    }

    return UsagePairingResult(
      sessions: List.unmodifiable(sessions),
      unmatchedForegroundCount: unmatchedForegroundCount,
      unmatchedBackgroundCount: unmatchedBackgroundCount,
      duplicateForegroundCount: duplicateCount,
      duplicateForegroundByPackage: Map.unmodifiable(duplicateByPackage),
    );
  }
}
