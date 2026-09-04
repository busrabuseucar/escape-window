import 'package:escape_window_ai/core/enums/risk_enums.dart';
import 'package:escape_window_ai/data/models/risk_assessment.dart';
import 'package:escape_window_ai/escape/rule_based_escape_window_engine.dart';
import 'package:flutter_test/flutter_test.dart';

RiskAssessment assessment({
  RiskLevel risk = RiskLevel.low,
  ConfidenceLevel confidence = ConfidenceLevel.high,
  List<RiskDriver> drivers = const [],
  bool safetyFlag = false,
}) {
  return RiskAssessment(
    timestamp: DateTime(2026, 9, 4, 7, 30),
    riskLevel: risk,
    confidence: confidence,
    bpi: drivers.contains(RiskDriver.behavioralPersistence) ? 0.7 : 0.1,
    srfi: drivers.contains(RiskDriver.selfRegulationFailure) ? 0.7 : 0.1,
    cvl: drivers.contains(RiskDriver.contextualVulnerability) ? 0.7 : 0.1,
    pbd: drivers.contains(RiskDriver.personalDeviation) ? 1.5 : 0.0,
    safetyFlag: safetyFlag,
    drivers: drivers,
    explanation: 'test',
    dermVersion: 'derm-rule-v0.2.0-pilot',
  );
}

void main() {
  const engine = RuleBasedEscapeWindowEngine();

  group('ESCAPE Window trigger gates', () {
    test('insufficient data always keeps the window closed', () {
      final result = engine.evaluate(
        assessment: assessment(
          risk: RiskLevel.insufficientData,
          confidence: ConfidenceLevel.insufficient,
        ),
        persistenceIsSufficient: true,
        cooldownActive: false,
        interventionEligible: true,
      );

      expect(result.state, EscapeWindowState.closed);
      expect(result.reason, contains('Yeterli güvenilir veri'));
    });

    test('cooldown blocks a new intervention even when risk is elevated', () {
      final result = engine.evaluate(
        assessment: assessment(
          risk: RiskLevel.elevated,
          confidence: ConfidenceLevel.high,
          drivers: const [
            RiskDriver.behavioralPersistence,
            RiskDriver.selfRegulationFailure,
          ],
        ),
        persistenceIsSufficient: true,
        cooldownActive: true,
        interventionEligible: true,
      );

      expect(result.state, EscapeWindowState.cooldown);
    });

    test('normal low-risk use never opens the window', () {
      final result = engine.evaluate(
        assessment: assessment(risk: RiskLevel.low),
        persistenceIsSufficient: true,
        cooldownActive: false,
        interventionEligible: true,
      );

      expect(result.state, EscapeWindowState.closed);
    });

    test('risk signal waits when the current moment is not intervention-eligible', () {
      final result = engine.evaluate(
        assessment: assessment(
          risk: RiskLevel.elevated,
          drivers: const [
            RiskDriver.behavioralPersistence,
            RiskDriver.selfRegulationFailure,
          ],
        ),
        persistenceIsSufficient: true,
        cooldownActive: false,
        interventionEligible: false,
      );

      expect(result.state, EscapeWindowState.observing);
      expect(result.reason, contains('uygun değil'));
    });

    test('WATCH does not open before persistence is sufficient', () {
      final result = engine.evaluate(
        assessment: assessment(
          risk: RiskLevel.watch,
          confidence: ConfidenceLevel.high,
          drivers: const [RiskDriver.selfRegulationFailure],
        ),
        persistenceIsSufficient: false,
        cooldownActive: false,
        interventionEligible: true,
      );

      expect(result.state, EscapeWindowState.observing);
      expect(result.reason, contains('süreklilik'));
    });

    test('WATCH opens only when persistence, confidence and eligibility all pass', () {
      final result = engine.evaluate(
        assessment: assessment(
          risk: RiskLevel.watch,
          confidence: ConfidenceLevel.medium,
          drivers: const [
            RiskDriver.behavioralPersistence,
            RiskDriver.selfRegulationFailure,
          ],
        ),
        persistenceIsSufficient: true,
        cooldownActive: false,
        interventionEligible: true,
      );

      expect(result.state, EscapeWindowState.active);
      expect(result.reason, contains('ESCAPE Window aktif'));
      expect(result.reason, contains('davranışsal süreklilik'));
      expect(result.reason, contains('öz-düzenleme başarısızlığı'));
    });

    test('ELEVATED opens when the full gate passes', () {
      final result = engine.evaluate(
        assessment: assessment(
          risk: RiskLevel.elevated,
          confidence: ConfidenceLevel.high,
          drivers: const [
            RiskDriver.behavioralPersistence,
            RiskDriver.selfRegulationFailure,
            RiskDriver.personalDeviation,
          ],
        ),
        persistenceIsSufficient: true,
        cooldownActive: false,
        interventionEligible: true,
      );

      expect(result.state, EscapeWindowState.active);
      expect(result.reason, contains('kişisel baseline sapması'));
    });

    test('low confidence cannot open the window even for elevated risk', () {
      final result = engine.evaluate(
        assessment: assessment(
          risk: RiskLevel.elevated,
          confidence: ConfidenceLevel.low,
          drivers: const [
            RiskDriver.behavioralPersistence,
            RiskDriver.selfRegulationFailure,
          ],
        ),
        persistenceIsSufficient: true,
        cooldownActive: false,
        interventionEligible: true,
      );

      expect(result.state, EscapeWindowState.observing);
      expect(result.reason, contains('koşulları henüz tamamlanmadı'));
    });

    test('single-day WATCH-like signal remains observing without persistence', () {
      final result = engine.evaluate(
        assessment: assessment(
          risk: RiskLevel.watch,
          confidence: ConfidenceLevel.medium,
          drivers: const [RiskDriver.contextualVulnerability],
        ),
        persistenceIsSufficient: false,
        cooldownActive: false,
        interventionEligible: true,
      );

      expect(result.state, EscapeWindowState.observing);
    });
  });
}
