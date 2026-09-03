import '../core/enums/risk_enums.dart';
import 'cooldown_policy.dart';
import 'intervention_models.dart';
import 'outcome_tracker.dart';

class InterventionSessionController {
  InterventionSessionController({
    OutcomeTracker? outcomeTracker,
    this.cooldownPolicy = const CooldownPolicy(),
  }) : outcomeTracker = outcomeTracker ?? OutcomeTracker();

  final OutcomeTracker outcomeTracker;
  final CooldownPolicy cooldownPolicy;

  DateTime? _cooldownUntil;

  DateTime? get cooldownUntil => _cooldownUntil;

  bool isCooldownActive(DateTime now) => cooldownPolicy.isCooldownActive(
        now: now,
        cooldownUntil: _cooldownUntil,
      );

  InterventionOutcome handleResponse({
    required InterventionRecommendation recommendation,
    required InterventionResponse response,
    required RiskLevel riskBefore,
    required double srfiBefore,
    DateTime? respondedAt,
  }) {
    final timestamp = respondedAt ?? DateTime.now();

    final outcome = outcomeTracker.recordResponse(
      recommendation: recommendation,
      response: response,
      riskBefore: riskBefore,
      srfiBefore: srfiBefore,
      recordedAt: timestamp,
    );

    _cooldownUntil = cooldownPolicy.cooldownUntil(
      response: response,
      respondedAt: timestamp,
    );

    return outcome;
  }

  void clearExpiredCooldown(DateTime now) {
    if (_cooldownUntil != null && !now.isBefore(_cooldownUntil!)) {
      _cooldownUntil = null;
    }
  }
}
