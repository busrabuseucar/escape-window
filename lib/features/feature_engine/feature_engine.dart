import '../../data/models/daily_feature_snapshot.dart';
import 'derived_feature_set.dart';

class FeatureEngine {
  const FeatureEngine();

  DerivedFeatureSet derive(List<DailyFeatureSnapshot> history) {
    if (history.isEmpty) {
      return const DerivedFeatureSet(
        threeDaySocialChange: 0,
        sevenDaySocialChange: 0,
        persistenceDays: 0,
        meanDataCompleteness: 0,
      );
    }

    final sorted = [...history]..sort((a, b) => a.date.compareTo(b.date));

    return DerivedFeatureSet(
      threeDaySocialChange: _windowChange(sorted, 3),
      sevenDaySocialChange: _windowChange(sorted, 7),
      persistenceDays: _persistenceDays(sorted),
      meanDataCompleteness: sorted
              .map((e) => e.dataCompleteness)
              .reduce((a, b) => a + b) /
          sorted.length,
    );
  }

  double _windowChange(List<DailyFeatureSnapshot> history, int window) {
    if (history.length < 2) return 0;

    final currentWindow = history.length >= window
        ? history.sublist(history.length - window)
        : history;
    final currentMean = _meanSocial(currentWindow);

    final precedingEnd = history.length - currentWindow.length;
    if (precedingEnd <= 0) return 0;

    final precedingStart =
        (precedingEnd - currentWindow.length).clamp(0, precedingEnd).toInt();
    final previousWindow = history.sublist(precedingStart, precedingEnd);
    if (previousWindow.isEmpty) return 0;

    final previousMean = _meanSocial(previousWindow);
    if (previousMean <= 0) return 0;

    return (currentMean - previousMean) / previousMean;
  }

  double _meanSocial(List<DailyFeatureSnapshot> values) =>
      values.map((e) => e.socialMediaTimeMinutes).reduce((a, b) => a + b) /
      values.length;

  int _persistenceDays(List<DailyFeatureSnapshot> history) {
    var count = 0;
    for (final day in history.reversed) {
      if (day.limitExceedanceCount > 0) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }
}
