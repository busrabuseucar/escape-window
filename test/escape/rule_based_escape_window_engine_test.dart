import 'package:escape_window_ai/core/enums/risk_enums.dart';
import 'package:escape_window_ai/data/models/risk_assessment.dart';
import 'package:escape_window_ai/escape/rule_based_escape_window_engine.dart';
import 'package:test/test.dart';

RiskAssessment assessment({
  RiskLevel risk = RiskLevel.watch,
  ConfidenceLevel confidence = ConfidenceLevel.high,
}) {
  return RiskAssessment(
    timestamp: DateTime(2026, 1, 1),
    riskLevel: risk,
    confidence: confidence,
    bpi: 0.7,
    srfi: 0.7,
    cvl: 0.5,
    pbd: 1.2,
    safetyFlag: false,
    drivers: const [
      RiskDriver.behavioralPersistence,
      RiskDriver.selfRegulationFailure,
    ],
    explanation: 'test',
    dermVersion: 'test',
  );
}

void main() {
  const engine = RuleBasedEscapeWindowEngine();

  test('insufficient data closes window', () {
    final result = engine.evaluate(
      assessment: assessment(
        risk: RiskLevel.insufficientData,
        confidence: ConfidenceLevel.insufficient,
      ),
      persistenceIsSufficient: false,
      cooldownActive: false,
      interventionEligible: true,
    );
    expect(result.state, EscapeWindowState.closed);
  });

  test('cooldown has priority after data sufficiency', () {
    final result = engine.evaluate(
      assessment: assessment(),
      persistenceIsSufficient: true,
      cooldownActive: true,
      interventionEligible: true,
    );
    expect(result.state, EscapeWindowState.cooldown);
  });

  test('low risk closes window', () {
    final result = engine.evaluate(
      assessment: assessment(risk: RiskLevel.low),
      persistenceIsSufficient: false,
      cooldownActive: false,
      interventionEligible: true,
    );
    expect(result.state, EscapeWindowState.closed);
  });

  test('watch without persistence stays observing', () {
    final result = engine.evaluate(
      assessment: assessment(risk: RiskLevel.watch),
      persistenceIsSufficient: false,
      cooldownActive: false,
      interventionEligible: true,
    );
    expect(result.state, EscapeWindowState.observing);
  });

  test('persistent risk with sufficient confidence becomes active', () {
    final result = engine.evaluate(
      assessment: assessment(risk: RiskLevel.elevated),
      persistenceIsSufficient: true,
      cooldownActive: false,
      interventionEligible: true,
    );
    expect(result.state, EscapeWindowState.active);
    expect(result.reason, contains('ESCAPE Window aktif'));
  });
}
