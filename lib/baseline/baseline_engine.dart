import '../data/models/baseline_profile.dart';
import '../data/models/daily_feature_snapshot.dart';

abstract interface class BaselineEngine {
  Future<List<BaselineProfile>> evaluate({
    required List<DailyFeatureSnapshot> history,
    required bool currentPeriodIsRisky,
  });

  /// Risky or insufficiently reliable periods must not silently redefine normal.
  bool shouldUpdateBaseline({
    required bool currentPeriodIsRisky,
    required double dataCompleteness,
  });
}
