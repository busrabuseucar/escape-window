import '../core/enums/risk_enums.dart';
import '../data/models/risk_assessment.dart';
import '../escape/escape_window_engine.dart';
import 'intervention_models.dart';

abstract interface class InterventionEngine {
  InterventionRecommendation? recommend({
    required EscapeWindowDecision windowDecision,
    required RiskAssessment assessment,
  });
}

class DeterministicInterventionEngine implements InterventionEngine {
  const DeterministicInterventionEngine();

  @override
  InterventionRecommendation? recommend({
    required EscapeWindowDecision windowDecision,
    required RiskAssessment assessment,
  }) {
    if (windowDecision.state != EscapeWindowState.active) return null;

    final drivers = assessment.drivers.toSet();

    if (drivers.contains(RiskDriver.selfRegulationFailure) &&
        drivers.contains(RiskDriver.personalDeviation)) {
      return InterventionRecommendation(
        type: InterventionType.goalReminder,
        title: 'Kendi hedefini hatırla',
        message:
            'Son günlerde kendi belirlediğin kullanım sınırı tekrar aşıldı ve kullanımın kişisel olağan düzeyinden sapma gösterdi. İstersen şimdi kısa bir ara verip hedefini yeniden uygulayabilirsin.',
        reason: 'SRFI + PBD birlikte etkin.',
        drivers: const [
          RiskDriver.selfRegulationFailure,
          RiskDriver.personalDeviation,
        ],
        allowDelay: true,
        allowDismiss: true,
      );
    }

    if (drivers.contains(RiskDriver.contextualVulnerability)) {
      return InterventionRecommendation(
        type: InterventionType.nightBreak,
        title: 'Gece kullanımına kısa bir ara',
        message:
            'Gece kullanımında son değerlendirme penceresine göre belirgin bir artış görüldü. Birkaç dakikalık ekran molası vermeyi ister misin?',
        reason: 'Bağlamsal hassasiyet sinyali baskın.',
        drivers: const [RiskDriver.contextualVulnerability],
        allowDelay: true,
        allowDismiss: true,
      );
    }

    if (drivers.contains(RiskDriver.behavioralPersistence) &&
        drivers.contains(RiskDriver.selfRegulationFailure)) {
      return InterventionRecommendation(
        type: InterventionType.patternFeedback,
        title: 'Bu örüntü birkaç gündür sürüyor',
        message:
            'Kullanım sınırı ihlalleri tek güne özgü görünmüyor; örüntü birkaç güne yayılmış durumda. İstersen bugün için daha küçük ve uygulanabilir bir kullanım hedefi seçebilirsin.',
        reason: 'BPI + SRFI birlikte etkin.',
        drivers: const [
          RiskDriver.behavioralPersistence,
          RiskDriver.selfRegulationFailure,
        ],
        allowDelay: true,
        allowDismiss: true,
      );
    }

    if (assessment.riskLevel == RiskLevel.elevated &&
        drivers.length >= 2) {
      return InterventionRecommendation(
        type: InterventionType.shortBreak,
        title: 'Kısa bir mola önerisi',
        message:
            'Birden fazla davranış sinyali aynı anda yükseldi. Şimdi kısa bir ekran molası vermek, örüntüyü kırmak için düşük yoğunluklu bir adım olabilir.',
        reason: 'Birden fazla erken-risk sürücüsü etkin.',
        drivers: assessment.drivers.take(2).toList(),
        allowDelay: true,
        allowDismiss: true,
      );
    }

    if (assessment.safetyFlag && assessment.riskLevel == RiskLevel.elevated) {
      return InterventionRecommendation(
        type: InterventionType.professionalSupportInfo,
        title: 'Destek seçeneklerini görmek ister misin?',
        message:
            'Bu sistem tanı koymaz. Davranış örüntüsü seni zorlamaya devam ediyorsa, güvendiğin bir uzmana veya uygun destek kaynaklarına başvurmayı değerlendirebilirsin.',
        reason: 'Yüksek risk örüntüsü ve güvenlik katmanı birlikte etkin.',
        drivers: const [RiskDriver.safetyGuardrail],
        allowDelay: true,
        allowDismiss: true,
      );
    }

    return InterventionRecommendation(
      type: InterventionType.shortBreak,
      title: 'Kısa bir ara vermek ister misin?',
      message:
          'ESCAPE Window aktif. Şimdi birkaç dakikalık kısa bir ekran molası deneyebilirsin.',
      reason: 'Aktif müdahale penceresi için genel düşük yoğunluklu öneri.',
      drivers: assessment.drivers,
      allowDelay: true,
      allowDismiss: true,
    );
  }
}
