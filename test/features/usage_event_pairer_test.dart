import 'package:escape_window_ai/features/usage_collector/usage_event_pairer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const pairer = UsageEventPairer();

  test('duplicate foreground resets duration start instead of over-counting', () {
    const minute = 60 * 1000;

    final result = pairer.pairForDuration(
      events: const [
        UsageEventSample(
          packageName: 'com.instagram.android',
          timestampMs: 1 * minute,
          eventType: 1,
        ),
        UsageEventSample(
          packageName: 'com.instagram.android',
          timestampMs: 89 * minute,
          eventType: 1,
        ),
        UsageEventSample(
          packageName: 'com.instagram.android',
          timestampMs: 132 * minute,
          eventType: 2,
        ),
      ],
      dayEndMs: 24 * 60 * minute,
    );

    expect(result.duplicateForegroundCount, 1);
    expect(result.duplicateForegroundByPackage['com.instagram.android'], 1);
    expect(result.sessions, hasLength(1));
    expect(result.sessions.single.durationMinutes.round(), 43);
  });

  test('ordinary foreground/background pairing remains unchanged', () {
    const minute = 60 * 1000;

    final result = pairer.pairForDuration(
      events: const [
        UsageEventSample(
          packageName: 'com.google.android.youtube',
          timestampMs: 10 * minute,
          eventType: 1,
        ),
        UsageEventSample(
          packageName: 'com.google.android.youtube',
          timestampMs: 74 * minute,
          eventType: 2,
        ),
      ],
      dayEndMs: 24 * 60 * minute,
    );

    expect(result.duplicateForegroundCount, 0);
    expect(result.sessions, hasLength(1));
    expect(result.sessions.single.durationMinutes.round(), 64);
  });
}
