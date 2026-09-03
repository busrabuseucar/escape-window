import '../core/enums/risk_enums.dart';
import '../data/models/baseline_profile.dart';
import '../data/models/risk_assessment.dart';

class HybridRiskResult {
  const HybridRiskResult({
    required this.assessment,
    required this.baselineProfiles,
    required this.baselineState,
    required this.baselineUpdateAllowed,
  });

  final RiskAssessment assessment;
  final List<BaselineProfile> baselineProfiles;
  final BaselineState baselineState;
  final bool baselineUpdateAllowed;
}
