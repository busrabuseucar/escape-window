import '../core/enums/risk_enums.dart';

enum InterventionType {
  goalReminder,
  nightBreak,
  shortBreak,
  patternFeedback,
  professionalSupportInfo,
}

enum InterventionResponse {
  accepted,
  delayed,
  dismissed,
  noResponse,
}

class InterventionRecommendation {
  const InterventionRecommendation({
    required this.type,
    required this.title,
    required this.message,
    required this.reason,
    required this.drivers,
    required this.allowDelay,
    required this.allowDismiss,
  });

  final InterventionType type;
  final String title;
  final String message;
  final String reason;
  final List<RiskDriver> drivers;
  final bool allowDelay;
  final bool allowDismiss;
}
