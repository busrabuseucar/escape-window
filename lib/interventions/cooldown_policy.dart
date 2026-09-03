import 'intervention_models.dart';

class CooldownPolicy {
  const CooldownPolicy({
    this.acceptedCooldown = const Duration(hours: 6),
    this.delayedCooldown = const Duration(hours: 2),
    this.dismissedCooldown = const Duration(hours: 12),
    this.noResponseCooldown = const Duration(hours: 6),
  });

  /// Provisional MVP engineering defaults. These durations are configurable
  /// and must be evaluated for burden, usability and intervention fatigue.
  final Duration acceptedCooldown;
  final Duration delayedCooldown;
  final Duration dismissedCooldown;
  final Duration noResponseCooldown;

  DateTime cooldownUntil({
    required InterventionResponse response,
    required DateTime respondedAt,
  }) {
    return respondedAt.add(_durationFor(response));
  }

  bool isCooldownActive({
    required DateTime now,
    required DateTime? cooldownUntil,
  }) {
    return cooldownUntil != null && now.isBefore(cooldownUntil);
  }

  Duration _durationFor(InterventionResponse response) {
    switch (response) {
      case InterventionResponse.accepted:
        return acceptedCooldown;
      case InterventionResponse.delayed:
        return delayedCooldown;
      case InterventionResponse.dismissed:
        return dismissedCooldown;
      case InterventionResponse.noResponse:
        return noResponseCooldown;
    }
  }
}
