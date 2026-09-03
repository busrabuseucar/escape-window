import 'package:escape_window_ai/core/enums/risk_enums.dart';
import 'package:escape_window_ai/interventions/cooldown_policy.dart';
import 'package:escape_window_ai/interventions/intervention_models.dart';
import 'package:escape_window_ai/interventions/intervention_session_controller.dart';
import 'package:escape_window_ai/interventions/outcome_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const recommendation = InterventionRecommendation(
    type: InterventionType.goalReminder,
    title: 'Hedefini hatırla',
    message: 'Kısa bir ara vermeyi deneyebilirsin.',
    reason: 'Test recommendation',
    drivers: [RiskDriver.selfRegulationFailure],
    allowDelay: true,
    allowDismiss: true,
  );

  test('response is recorded without changing the risk score', () {
    final tracker = OutcomeTracker();
    final outcome = tracker.recordResponse(
      recommendation: recommendation,
      response: InterventionResponse.dismissed,
      riskBefore: RiskLevel.watch,
      srfiBefore: 0.7,
      recordedAt: DateTime(2026, 1, 1, 10),
    );

    expect(outcome.response, InterventionResponse.dismissed);
    expect(outcome.riskBefore, RiskLevel.watch);
    expect(outcome.srfiBefore, 0.7);
    expect(tracker.outcomes.length, 1);
  });

  test('follow-up is stored as observational data', () {
    final tracker = OutcomeTracker();
    tracker.recordResponse(
      recommendation: recommendation,
      response: InterventionResponse.accepted,
      riskBefore: RiskLevel.elevated,
      srfiBefore: 0.9,
      recordedAt: DateTime(2026, 1, 1, 10),
    );

    final updated = tracker.attachFollowUp(
      outcomeIndex: 0,
      riskAfter: RiskLevel.watch,
      srfiAfter: 0.5,
    );

    expect(updated.hasFollowUp, isTrue);
    expect(updated.riskAfter, RiskLevel.watch);
  });

  test('dismissal creates cooldown but does not escalate risk', () {
    final controller = InterventionSessionController(
      cooldownPolicy: const CooldownPolicy(
        dismissedCooldown: Duration(hours: 12),
      ),
    );
    final respondedAt = DateTime(2026, 1, 1, 10);

    final outcome = controller.handleResponse(
      recommendation: recommendation,
      response: InterventionResponse.dismissed,
      riskBefore: RiskLevel.watch,
      srfiBefore: 0.6,
      respondedAt: respondedAt,
    );

    expect(outcome.riskBefore, RiskLevel.watch);
    expect(controller.isCooldownActive(DateTime(2026, 1, 1, 11)), isTrue);
    expect(controller.isCooldownActive(DateTime(2026, 1, 1, 23)), isFalse);
  });

  test('delayed response receives shorter configured cooldown', () {
    const policy = CooldownPolicy(
      delayedCooldown: Duration(hours: 2),
    );
    final until = policy.cooldownUntil(
      response: InterventionResponse.delayed,
      respondedAt: DateTime(2026, 1, 1, 10),
    );

    expect(until, DateTime(2026, 1, 1, 12));
  });

  test('expired cooldown can be cleared', () {
    final controller = InterventionSessionController();
    controller.handleResponse(
      recommendation: recommendation,
      response: InterventionResponse.accepted,
      riskBefore: RiskLevel.watch,
      srfiBefore: 0.5,
      respondedAt: DateTime(2026, 1, 1, 10),
    );

    controller.clearExpiredCooldown(DateTime(2026, 1, 2));
    expect(controller.cooldownUntil, isNull);
  });
}
