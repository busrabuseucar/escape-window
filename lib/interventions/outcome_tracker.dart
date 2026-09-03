import '../core/enums/risk_enums.dart';
import 'intervention_models.dart';

class InterventionOutcome {
  const InterventionOutcome({
    required this.interventionType,
    required this.response,
    required this.recordedAt,
    required this.riskBefore,
    required this.srfiBefore,
    this.riskAfter,
    this.srfiAfter,
  });

  final InterventionType interventionType;
  final InterventionResponse response;
  final DateTime recordedAt;
  final RiskLevel riskBefore;
  final double srfiBefore;
  final RiskLevel? riskAfter;
  final double? srfiAfter;

  /// Outcome tracking is observational in the MVP. A change after an
  /// intervention must not be interpreted as proof that the intervention
  /// caused the change.
  bool get hasFollowUp => riskAfter != null || srfiAfter != null;
}

class OutcomeTracker {
  final List<InterventionOutcome> _outcomes = [];

  List<InterventionOutcome> get outcomes => List.unmodifiable(_outcomes);

  InterventionOutcome recordResponse({
    required InterventionRecommendation recommendation,
    required InterventionResponse response,
    required RiskLevel riskBefore,
    required double srfiBefore,
    DateTime? recordedAt,
  }) {
    final outcome = InterventionOutcome(
      interventionType: recommendation.type,
      response: response,
      recordedAt: recordedAt ?? DateTime.now(),
      riskBefore: riskBefore,
      srfiBefore: srfiBefore,
    );
    _outcomes.add(outcome);
    return outcome;
  }

  InterventionOutcome attachFollowUp({
    required int outcomeIndex,
    required RiskLevel riskAfter,
    required double srfiAfter,
  }) {
    final current = _outcomes[outcomeIndex];
    final updated = InterventionOutcome(
      interventionType: current.interventionType,
      response: current.response,
      recordedAt: current.recordedAt,
      riskBefore: current.riskBefore,
      srfiBefore: current.srfiBefore,
      riskAfter: riskAfter,
      srfiAfter: srfiAfter,
    );
    _outcomes[outcomeIndex] = updated;
    return updated;
  }
}
