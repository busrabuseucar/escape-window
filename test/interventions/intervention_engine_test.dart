import 'package:escape_window_ai/core/enums/risk_enums.dart';
import 'package:escape_window_ai/data/models/risk_assessment.dart';
import 'package:escape_window_ai/escape/escape_window_engine.dart';
import 'package:escape_window_ai/interventions/intervention_engine.dart';
import 'package:escape_window_ai/interventions/intervention_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = DeterministicInterventionEngine();

  RiskAssessment assessment({
    RiskLevel level = RiskLevel.watch,
    List<RiskDriver> drivers = const [],
    bool safetyFlag = false,
  }) {
    return RiskAssessment(
      timestamp: DateTime(2026, 1, 1),
      riskLevel: level,
      confidence: ConfidenceLevel.high,
      bpi: 0.7,
      srfi: 0.7,
      cvl: 0.2,
      pbd: 1.2,
      safetyFlag: safetyFlag,
      drivers: drivers,
      explanation: 'test',
      dermVersion: 'test',
    );
  }

  const active = EscapeWindowDecision(
    state: EscapeWindowState.active,
    reason: 'test',
  );

  test('returns no intervention when window is not active', () {
    const closed = EscapeWindowDecision(
      state: EscapeWindowState.closed,
      reason: 'test',
    );

    final result = engine.recommend(
      windowDecision: closed,
      assessment: assessment(
        drivers: const [RiskDriver.selfRegulationFailure],
      ),
    );

    expect(result, isNull);
  });

  test('SRFI plus PBD selects goal reminder', () {
    final result = engine.recommend(
      windowDecision: active,
      assessment: assessment(
        drivers: const [
          RiskDriver.selfRegulationFailure,
          RiskDriver.personalDeviation,
        ],
      ),
    );

    expect(result?.type, InterventionType.goalReminder);
  });

  test('contextual vulnerability selects night break', () {
    final result = engine.recommend(
      windowDecision: active,
      assessment: assessment(
        drivers: const [RiskDriver.contextualVulnerability],
      ),
    );

    expect(result?.type, InterventionType.nightBreak);
  });

  test('BPI plus SRFI selects pattern feedback', () {
    final result = engine.recommend(
      windowDecision: active,
      assessment: assessment(
        drivers: const [
          RiskDriver.behavioralPersistence,
          RiskDriver.selfRegulationFailure,
        ],
      ),
    );

    expect(result?.type, InterventionType.patternFeedback);
  });

  test('elevated multi-driver case falls back to short break', () {
    final result = engine.recommend(
      windowDecision: active,
      assessment: assessment(
        level: RiskLevel.elevated,
        drivers: const [
          RiskDriver.behavioralPersistence,
          RiskDriver.personalDeviation,
        ],
      ),
    );

    expect(result?.type, InterventionType.shortBreak);
  });

  test('all recommendations can be delayed or dismissed', () {
    final result = engine.recommend(
      windowDecision: active,
      assessment: assessment(
        drivers: const [RiskDriver.contextualVulnerability],
      ),
    );

    expect(result?.allowDelay, isTrue);
    expect(result?.allowDismiss, isTrue);
  });
}
