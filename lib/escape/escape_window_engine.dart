import '../core/enums/risk_enums.dart';
import '../data/models/risk_assessment.dart';

class EscapeWindowDecision {
  const EscapeWindowDecision({
    required this.state,
    required this.reason,
  });

  final EscapeWindowState state;
  final String reason;
}

abstract interface class EscapeWindowEngine {
  EscapeWindowDecision evaluate({
    required RiskAssessment assessment,
    required bool persistenceIsSufficient,
    required bool cooldownActive,
    required bool interventionEligible,
  });
}
