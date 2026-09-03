import '../data/models/baseline_profile.dart';
import '../data/models/daily_feature_snapshot.dart';
import '../data/models/risk_assessment.dart';

abstract interface class DermEngine {
  RiskAssessment evaluate({
    required List<DailyFeatureSnapshot> recentFeatures,
    required List<BaselineProfile> baselineProfiles,
    required double userDailyLimitMinutes,
  });
}
