import '../../core/enums/risk_enums.dart';

class BaselineProfile {
  const BaselineProfile({
    required this.featureName,
    required this.mean,
    required this.standardDeviation,
    required this.confidence,
    required this.state,
    required this.updatedAt,
  });

  final String featureName;
  final double mean;
  final double standardDeviation;
  final double confidence;
  final BaselineState state;
  final DateTime updatedAt;
}
