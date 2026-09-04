# DERM v0.2 Pilot Specification

Status: **pre-registered pilot engineering specification**  
Runtime version: `derm-rule-v0.2.0-pilot`

This specification freezes the DERM calculation and intervention semantics to be used in the pilot. Parameters are engineering starting values, not clinical cut-offs. After outcome data are inspected, changes must be versioned as a new algorithm; thresholds must not be silently tuned on the same pilot and then reported as if they had been pre-specified.

## Evaluation window

- Baseline/calibration: 7 completed days.
- Current evaluation: 7 completed days.
- Current risky periods do not update the personal baseline.
- Confidence remains separate from risk.
- PBD is an explanation/calibration signal and never independently raises the final risk level.

## Core components

### BPI — Behavioral Persistence Index

BPI measures whether self-set-limit violations are repeated and sustained.

```
violation_fraction = violation_days / measurable_days
streak_fraction = longest_consecutive_violation_streak / measurable_days
BPI = 0.5 * violation_fraction + 0.5 * streak_fraction
```

Range: `[0, 1]`.

Reason for v0.2 change: v0.1 BPI and SRFI were effectively the same signal when data completeness was high. Pilot v0.2 separates persistence from severity.

### SRFI — Self-Regulation Failure Index

SRFI measures the magnitude of self-set-limit exceedance.

For each measurable day:

```
daily_severity = clamp(limit_exceedance_minutes / user_daily_limit_minutes, 0, 1)
SRFI = mean(daily_severity)
```

Range: `[0, 1]`.

A zero/non-positive user goal produces `0` rather than an invalid score.

### CVL — Contextual Vulnerability Level

CVL measures what share of observed screen time occurred in the configured sensitive/night window.

```
CVL = clamp(sum(night_usage_minutes) / sum(total_screen_time_minutes), 0, 1)
```

Range: `[0, 1]`.

Reason for v0.2 change: the previous fixed 60-minute reference was an arbitrary engineering constant. The v0.2 signal is a directly interpretable within-person contextual proportion.

### PBD — Personal Baseline Deviation

PBD measures positive deviation of the recent **mean** selected-social usage from the personal baseline.

```
z = (recent_mean_social - baseline_mean_social) / (baseline_sd_social + epsilon)
PBD = clamp(z, 0, 3)
```

PBD is not a core risk component. It can add an explanation/driver only.

## Confidence

Confidence uses data completeness and baseline confidence.

- No recent data: `INSUFFICIENT`.
- Mean completeness < 0.50: `INSUFFICIENT`.
- No baseline:
  - completeness >= 0.85 → `MEDIUM`
  - otherwise → `LOW`
- Baseline available:
  - completeness >= 0.85 and mean baseline confidence >= 0.70 → `HIGH`
  - otherwise → `MEDIUM`

These are pilot engineering settings.

## Risk gates

Provisional thresholds:

- watch component threshold: `0.40`
- elevated component threshold: `0.65`
- PBD explanation threshold: `1.0`

Decision:

1. If confidence is insufficient → `INSUFFICIENT_DATA`.
2. If at least **two independent core components** among BPI, SRFI and CVL are >= 0.65 → `ELEVATED`.
3. Else if any core component is >= 0.40 → `WATCH`.
4. Else → `LOW`.

PBD never counts toward the two-component elevated gate.

## Cold-start safety guardrail

When no reliable stable baseline exists:

```
safety_flag = BPI >= 0.40 AND SRFI >= 0.40
```

The guardrail keeps repeated meaningful self-regulation failure visible during cold start. It is not a diagnosis.

## Baseline contamination protection

If current risk is WATCH or ELEVATED, the baseline state is reported as `FROZEN` and the current period is not absorbed into the normal profile.

## ESCAPE Window

The intervention window remains closed when:

- risk/confidence is insufficient,
- risk is LOW, or
- cooldown is active.

WATCH risk remains `OBSERVING` until persistence is sufficient. ACTIVE requires:

- WATCH or ELEVATED,
- sufficient persistence,
- MEDIUM/HIGH confidence,
- intervention eligibility,
- no active cooldown.

## Intervention priority

When the window is ACTIVE:

1. `safetyFlag + ELEVATED` → professional support information.
2. `SRFI + PBD` → personal goal reminder.
3. `CVL` → night/sensitive-window break.
4. `BPI + SRFI` → persistent-pattern feedback.
5. `ELEVATED + >=2 drivers` → short break.
6. Otherwise → general short break.

The professional-support branch is deliberately evaluated first so it cannot be shadowed by the generic elevated branch.

## Cooldown defaults

Current pilot defaults:

- accepted: 6 h
- delayed: 2 h
- dismissed: 12 h
- no response: 6 h

These settings are burden-management defaults and must be evaluated for intervention fatigue.

## Pilot analysis rules

- The algorithm version is recorded with every assessment/intervention.
- The v0.2 rules are frozen before pilot outcome inspection.
- Threshold/weight changes after pilot start require a new version.
- Calibration and independent validation data must be separated in a later adequately powered study.
- No `% accuracy` claim is allowed before a reference definition and independent validation analysis exist.
- Technical validation is not clinical validation.

## Known limitations

- Component thresholds are provisional.
- No clinical cut-off is claimed.
- CVL is a context proportion, not proof of harm.
- User-set limits may vary in realism and should be analyzed as a design variable.
- PBD depends on baseline variability and remains an explanatory signal only.
- Pilot results are expected to inform v0.3 rather than prove final validity.
