import '../core/enums/risk_enums.dart';
import '../data/models/risk_assessment.dart';
import 'escape_window_engine.dart';

class RuleBasedEscapeWindowEngine implements EscapeWindowEngine {
  const RuleBasedEscapeWindowEngine();

  @override
  EscapeWindowDecision evaluate({
    required RiskAssessment assessment,
    required bool persistenceIsSufficient,
    required bool cooldownActive,
    required bool interventionEligible,
  }) {
    if (assessment.confidence == ConfidenceLevel.insufficient ||
        assessment.riskLevel == RiskLevel.insufficientData) {
      return const EscapeWindowDecision(
        state: EscapeWindowState.closed,
        reason: 'Yeterli güvenilir veri olmadığı için müdahale penceresi kapalı.',
      );
    }

    if (cooldownActive) {
      return const EscapeWindowDecision(
        state: EscapeWindowState.cooldown,
        reason: 'Yakın zamanda müdahale gösterildiği için cooldown aktif.',
      );
    }

    if (assessment.riskLevel == RiskLevel.low) {
      return const EscapeWindowDecision(
        state: EscapeWindowState.closed,
        reason: 'Belirgin erken-risk sinyali bulunmadığı için pencere kapalı.',
      );
    }

    if (!interventionEligible) {
      return const EscapeWindowDecision(
        state: EscapeWindowState.observing,
        reason: 'Risk sinyali var ancak kullanıcı şu anda müdahale için uygun değil.',
      );
    }

    if (assessment.riskLevel == RiskLevel.watch && !persistenceIsSufficient) {
      return const EscapeWindowDecision(
        state: EscapeWindowState.observing,
        reason: 'Risk sinyali izleniyor ancak henüz yeterli süreklilik oluşmadı.',
      );
    }

    final confidenceSufficient = assessment.confidence == ConfidenceLevel.medium ||
        assessment.confidence == ConfidenceLevel.high;

    if ((assessment.riskLevel == RiskLevel.watch ||
            assessment.riskLevel == RiskLevel.elevated) &&
        persistenceIsSufficient &&
        confidenceSufficient &&
        interventionEligible) {
      return EscapeWindowDecision(
        state: EscapeWindowState.active,
        reason: _activeReason(assessment),
      );
    }

    return const EscapeWindowDecision(
      state: EscapeWindowState.observing,
      reason: 'Risk sinyali mevcut ancak aktif müdahale koşulları henüz tamamlanmadı.',
    );
  }

  String _activeReason(RiskAssessment assessment) {
    final drivers = assessment.drivers.map((driver) {
      switch (driver) {
        case RiskDriver.behavioralPersistence:
          return 'davranışsal süreklilik';
        case RiskDriver.selfRegulationFailure:
          return 'öz-düzenleme başarısızlığı';
        case RiskDriver.contextualVulnerability:
          return 'bağlamsal hassasiyet';
        case RiskDriver.personalDeviation:
          return 'kişisel baseline sapması';
        case RiskDriver.safetyGuardrail:
          return 'güvenlik katmanı';
      }
    }).toList();

    final suffix = drivers.isEmpty ? '' : ' Başlıca nedenler: ${drivers.join(', ')}.';
    return 'Risk, süreklilik ve güven koşulları sağlandığı için ESCAPE Window aktif.$suffix';
  }
}
