import '../../core/enums/risk_enums.dart';

class RiskAssessment {
  const RiskAssessment({
    required this.timestamp,
    required this.riskLevel,
    required this.confidence,
    required this.bpi,
    required this.srfi,
    required this.cvl,
    required this.pbd,
    required this.safetyFlag,
    required this.drivers,
    required this.explanation,
    required this.dermVersion,
  });

  final DateTime timestamp;
  final RiskLevel riskLevel;
  final ConfidenceLevel confidence;
  final double bpi;
  final double srfi;
  final double cvl;
  final double pbd;
  final bool safetyFlag;
  final List<RiskDriver> drivers;
  final String explanation;
  final String dermVersion;
}
