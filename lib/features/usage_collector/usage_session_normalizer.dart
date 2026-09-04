/// A package-level foreground interval reconstructed from Android UsageEvents.
class UsageSessionWindow {
  const UsageSessionWindow({
    required this.packageName,
    required this.startMs,
    required this.endMs,
  });

  final String packageName;
  final int startMs;
  final int endMs;

  double get durationMinutes => (endMs - startMs) / 60000.0;
}

/// Converts raw package foreground intervals into user-facing interaction
/// episodes.
///
/// Android UsageEvents can emit foreground/background transitions while a user
/// is still interacting with the same app (for example during short internal
/// activity transitions). Counting every transition as a new session can make
/// the metric misleading. We therefore merge intervals from the same package
/// when the interruption between them is at most [interruptionTolerance].
///
/// This normalizer is intentionally used only for session count/mean-session
/// metrics. Screen-time totals continue to use the raw reconstructed intervals
/// so the risk pipeline is not changed by this presentation-level correction.
class UsageSessionNormalizer {
  const UsageSessionNormalizer({
    this.interruptionTolerance = const Duration(seconds: 30),
  });

  final Duration interruptionTolerance;

  List<UsageSessionWindow> mergeInteractionEpisodes(
    Iterable<UsageSessionWindow> sessions,
  ) {
    final byPackage = <String, List<UsageSessionWindow>>{};

    for (final session in sessions) {
      if (session.packageName.isEmpty || session.endMs <= session.startMs) {
        continue;
      }
      byPackage.putIfAbsent(session.packageName, () => []).add(session);
    }

    final merged = <UsageSessionWindow>[];
    final toleranceMs = interruptionTolerance.inMilliseconds;

    for (final entry in byPackage.entries) {
      final packageSessions = entry.value
        ..sort((a, b) => a.startMs.compareTo(b.startMs));

      var current = packageSessions.first;
      for (final next in packageSessions.skip(1)) {
        final gapMs = next.startMs - current.endMs;
        if (gapMs <= toleranceMs) {
          current = UsageSessionWindow(
            packageName: current.packageName,
            startMs: current.startMs,
            endMs: next.endMs > current.endMs ? next.endMs : current.endMs,
          );
        } else {
          merged.add(current);
          current = next;
        }
      }
      merged.add(current);
    }

    merged.sort((a, b) => a.startMs.compareTo(b.startMs));
    return merged;
  }
}
