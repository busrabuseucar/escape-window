import '../../data/models/daily_feature_snapshot.dart';

class DemoDataProvider {
  const DemoDataProvider();

  List<DailyFeatureSnapshot> normalScenario() => _buildScenario(
        socialMinutes: [105, 112, 108, 115, 110, 118, 111],
        nightMinutes: [12, 15, 11, 14, 13, 16, 12],
        limitExceedances: [0, 0, 0, 0, 0, 0, 0],
      );

  List<DailyFeatureSnapshot> persistentRiskScenario() => _buildScenario(
        socialMinutes: [110, 115, 145, 170, 190, 205, 215],
        nightMinutes: [12, 14, 35, 48, 60, 72, 80],
        limitExceedances: [0, 0, 1, 1, 1, 1, 1],
      );

  List<DailyFeatureSnapshot> _buildScenario({
    required List<int> socialMinutes,
    required List<int> nightMinutes,
    required List<int> limitExceedances,
  }) {
    final start = DateTime(2026, 1, 1);
    return List.generate(socialMinutes.length, (index) {
      final social = socialMinutes[index].toDouble();
      return DailyFeatureSnapshot(
        date: start.add(Duration(days: index)),
        totalScreenTimeMinutes: social + 90,
        socialMediaTimeMinutes: social,
        nightUsageMinutes: nightMinutes[index].toDouble(),
        sessionCount: 25 + index,
        meanSessionDurationMinutes: 8 + index * 0.5,
        limitExceedanceCount: limitExceedances[index],
        limitExceedanceMinutes:
            limitExceedances[index] == 0 ? 0 : (social - 120).clamp(0, double.infinity).toDouble(),
        dataCompleteness: 1.0,
      );
    });
  }
}
