import '../baseline/pbd_calculator.dart';
import '../core/enums/risk_enums.dart';
import '../data/models/baseline_profile.dart';
import '../data/models/daily_feature_snapshot.dart';
import '../data/models/risk_assessment.dart';
import 'bpi_calculator.dart';
import 'confidence_engine.dart';
import 'cvl_calculator.dart';
import 'derm_engine.dart';
import 'srfi_calculator.dart';

class DermRuleConfig {
  const DermRuleConfig({
    this.watchComponentThreshold = 0.40,
    this.elevatedComponentThreshold = 0.65,
    this.personalDeviationWatchZ = 1.0,
  });

  /// Pre-registered pilot engineering settings. They are intentionally kept
  /// separate from clinical claims and must not be changed mid-pilot after
  /// outcome data are inspected.
  final double watchComponentThreshold;
  final double elevatedComponentThreshold;
  final double personalDeviationWatchZ;
}

class RuleBasedDermEngine implements DermEngine {
  const RuleBasedDermEngine({
    this.config = const DermRuleConfig(),
    this.bpiCalculator = const BpiCalculator(),
    this.srfiCalculator = const SrfiCalculator(),
    this.cvlCalculator = const CvlCalculator(),
    this.pbdCalculator = const PbdCalculator(),
    this.confidenceEngine = const ConfidenceEngine(),
  });

  static const version = 'derm-rule-v0.2.0-pilot';

  final DermRuleConfig config;
  final BpiCalculator bpiCalculator;
  final SrfiCalculator srfiCalculator;
  final CvlCalculator cvlCalculator;
  final PbdCalculator pbdCalculator;
  final ConfidenceEngine confidenceEngine;

  @override
  RiskAssessment evaluate({
    required List<DailyFeatureSnapshot> recentFeatures,
    required List<BaselineProfile> baselineProfiles,
    required double userDailyLimitMinutes,
  }) {
    final confidence = confidenceEngine.evaluate(
      recentFeatures: recentFeatures,
      baselineProfiles: baselineProfiles,
    );

    if (recentFeatures.isEmpty || confidence == ConfidenceLevel.insufficient) {
      return RiskAssessment(
        timestamp: DateTime.now(),
        riskLevel: RiskLevel.insufficientData,
        confidence: ConfidenceLevel.insufficient,
        bpi: 0,
        srfi: 0,
        cvl: 0,
        pbd: 0,
        safetyFlag: false,
        drivers: const [],
        explanation: 'Güvenilir bir değerlendirme için yeterli veri yok.',
        dermVersion: version,
      );
    }

    final bpi = bpiCalculator.calculate(recentFeatures);
    final srfi = srfiCalculator.calculate(
      recentFeatures,
      userDailyLimitMinutes: userDailyLimitMinutes,
    );
    final cvl = cvlCalculator.calculate(recentFeatures);
    final pbd = _calculatePbd(recentFeatures, baselineProfiles);

    final componentScores = <RiskDriver, double>{
      RiskDriver.behavioralPersistence: bpi,
      RiskDriver.selfRegulationFailure: srfi,
      RiskDriver.contextualVulnerability: cvl,
    };

    final elevatedDrivers = componentScores.entries
        .where((e) => e.value >= config.elevatedComponentThreshold)
        .map((e) => e.key)
        .toList();
    final watchDrivers = componentScores.entries
        .where((e) => e.value >= config.watchComponentThreshold)
        .map((e) => e.key)
        .toList();

    final baselineReliable = baselineProfiles.any(
      (profile) =>
          profile.state == BaselineState.stable && profile.confidence >= 0.5,
    );

    // Cold-start guardrail. Repeated and meaningful self-regulation failure
    // remains visible even before a trustworthy personal baseline exists.
    final safetyFlag = !baselineReliable &&
        bpi >= config.watchComponentThreshold &&
        srfi >= config.watchComponentThreshold;

    final drivers = <RiskDriver>{...watchDrivers};
    if (pbd >= config.personalDeviationWatchZ) {
      drivers.add(RiskDriver.personalDeviation);
    }
    if (safetyFlag) drivers.add(RiskDriver.safetyGuardrail);

    RiskLevel level;
    if (elevatedDrivers.length >= 2) {
      // ELEVATED requires convergence of at least two independent core signals.
      // PBD never counts toward this gate.
      level = RiskLevel.elevated;
    } else if (watchDrivers.isNotEmpty || safetyFlag) {
      level = RiskLevel.watch;
    } else {
      level = RiskLevel.low;
    }

    return RiskAssessment(
      timestamp: DateTime.now(),
      riskLevel: level,
      confidence: confidence,
      bpi: bpi,
      srfi: srfi,
      cvl: cvl,
      pbd: pbd,
      safetyFlag: safetyFlag,
      drivers: drivers.toList(),
      explanation: _explain(
        level: level,
        bpi: bpi,
        srfi: srfi,
        cvl: cvl,
        pbd: pbd,
        safetyFlag: safetyFlag,
      ),
      dermVersion: version,
    );
  }

  double _calculatePbd(
    List<DailyFeatureSnapshot> recentFeatures,
    List<BaselineProfile> baselineProfiles,
  ) {
    final matching = baselineProfiles.where(
      (profile) => profile.featureName == 'social_media_time',
    );
    if (matching.isEmpty || recentFeatures.isEmpty) return 0;

    final baseline = matching.first;
    final measurable = recentFeatures
        .where((day) => day.dataCompleteness > 0)
        .toList(growable: false);
    if (measurable.isEmpty) return 0;

    final recentMean = measurable
            .map((day) => day.socialMediaTimeMinutes)
            .reduce((a, b) => a + b) /
        measurable.length;

    return pbdCalculator.calculate(
      currentValue: recentMean,
      baselineMean: baseline.mean,
      baselineStandardDeviation: baseline.standardDeviation,
    );
  }

  String _explain({
    required RiskLevel level,
    required double bpi,
    required double srfi,
    required double cvl,
    required double pbd,
    required bool safetyFlag,
  }) {
    if (level == RiskLevel.low) {
      return 'Son değerlendirme penceresinde tekrar eden belirgin bir erken-risk örüntüsü görülmedi.';
    }

    final reasons = <String>[];
    if (srfi >= config.watchComponentThreshold) {
      reasons.add('kendi belirlediğin kullanım sınırı anlamlı miktarda aşıldı');
    }
    if (bpi >= config.watchComponentThreshold) {
      reasons.add('sınır aşımı örüntüsü birden fazla güne ve ardışık günlere yayıldı');
    }
    if (cvl >= config.watchComponentThreshold) {
      reasons.add('kullanımın önemli bir bölümü hassas/gece saatlerinde gerçekleşti');
    }
    if (pbd >= config.personalDeviationWatchZ) {
      reasons.add('son dönem kullanımın kişisel olağan düzeyinin üzerine çıktı');
    }
    if (safetyFlag) {
      reasons.add('kişisel baseline henüz yeterince güvenilir olmadığı için güvenlik katmanı devrede');
    }

    return '${reasons.join('; ')}.';
  }
}
