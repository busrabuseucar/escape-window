import 'package:flutter_test/flutter_test.dart';
import 'package:escape_window_ai/features/usage_collector/usage_session_normalizer.dart';

void main() {
  const normalizer = UsageSessionNormalizer();

  test('merges same-package intervals separated by 30 seconds or less', () {
    final result = normalizer.mergeInteractionEpisodes(const [
      UsageSessionWindow(
        packageName: 'com.example.social',
        startMs: 0,
        endMs: 60000,
      ),
      UsageSessionWindow(
        packageName: 'com.example.social',
        startMs: 85000,
        endMs: 180000,
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.startMs, 0);
    expect(result.single.endMs, 180000);
  });

  test('keeps same-package intervals separate when interruption exceeds 30 seconds', () {
    final result = normalizer.mergeInteractionEpisodes(const [
      UsageSessionWindow(
        packageName: 'com.example.social',
        startMs: 0,
        endMs: 60000,
      ),
      UsageSessionWindow(
        packageName: 'com.example.social',
        startMs: 91000,
        endMs: 180000,
      ),
    ]);

    expect(result, hasLength(2));
  });

  test('never merges intervals from different packages', () {
    final result = normalizer.mergeInteractionEpisodes(const [
      UsageSessionWindow(
        packageName: 'com.example.social.a',
        startMs: 0,
        endMs: 60000,
      ),
      UsageSessionWindow(
        packageName: 'com.example.social.b',
        startMs: 61000,
        endMs: 120000,
      ),
    ]);

    expect(result, hasLength(2));
  });

  test('merges overlapping intervals for the same package', () {
    final result = normalizer.mergeInteractionEpisodes(const [
      UsageSessionWindow(
        packageName: 'com.example.social',
        startMs: 0,
        endMs: 120000,
      ),
      UsageSessionWindow(
        packageName: 'com.example.social',
        startMs: 60000,
        endMs: 180000,
      ),
    ]);

    expect(result, hasLength(1));
    expect(result.single.endMs, 180000);
  });

  test('drops invalid zero or negative duration intervals', () {
    final result = normalizer.mergeInteractionEpisodes(const [
      UsageSessionWindow(
        packageName: 'com.example.social',
        startMs: 1000,
        endMs: 1000,
      ),
      UsageSessionWindow(
        packageName: 'com.example.social',
        startMs: 2000,
        endMs: 1000,
      ),
    ]);

    expect(result, isEmpty);
  });
}
