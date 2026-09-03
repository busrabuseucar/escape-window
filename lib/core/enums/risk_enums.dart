enum RiskLevel {
  low,
  watch,
  elevated,
  insufficientData,
}

enum ConfidenceLevel {
  low,
  medium,
  high,
  insufficient,
}

enum BaselineState {
  calibrating,
  stable,
  frozen,
  recalibrating,
}

enum EscapeWindowState {
  closed,
  observing,
  active,
  cooldown,
}

enum RiskDriver {
  behavioralPersistence,
  selfRegulationFailure,
  contextualVulnerability,
  personalDeviation,
  safetyGuardrail,
}
