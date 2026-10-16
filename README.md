# ESCAPE Window AI

**Privacy-first Android behavioral risk system with real UsageStats ingestion, explainable decision logic, and physical-device validation.**

ESCAPE Window AI is an Android-first Flutter MVP for evaluating early signs of self-regulation loss in problematic smartphone and social-media use among university-age users (18–24). It combines a personal behavioral baseline, explainable risk logic, and low-intensity micro-interventions without reading private message content or presenting itself as a clinical diagnostic system.

> **Status:** MVP `0.1.0+1`. The September device-validation record describes an earlier revision; the October changes require a new physical-device regression run.

## Engineering at a glance

| Area | Implementation |
| --- | --- |
| Mobile | Flutter / Dart, Android-first |
| Device data | Android UsageStats via native MethodChannel bridge |
| Personalization | 14 completed-day pipeline with personal baseline |
| Decision system | Explainable DERM risk + confidence logic |
| Intervention | State-based ESCAPE Window and micro-intervention flow |
| Privacy | Explicit consent, tracked-app selection, local-first/minimized data path |
| Validation | Physical Android device, historical real UsageStats |
| Quality gate | `flutter analyze` → `flutter test` → Android debug APK build |

## Implemented data flow

The working MVP implements the full path from device data to an explainable intervention:

```text
Explicit consent
      ↓
Android Usage Access
      ↓
Tracked-app selection
      ↓
Android UsageStats
      ↓
Native MethodChannel bridge
      ↓
Usage-event normalization
      ↓
DailyFeatureSnapshot
      ↓
Personal Baseline
      ↓
DERM
      ↓
Risk + Confidence + Explanation
      ↓
ESCAPE Window
      ↓
Micro-intervention
      ↓
Outcome / History
```

The application reads completed-day Android usage events, derives behavioral snapshots, establishes a personal baseline, produces an explainable early-risk state, selects a micro-intervention when appropriate, and records the user's response.

## Real-device validation

The MVP was tested on a physical Android device on **03–04 September 2026**. The validated flow included:

- explicit-consent onboarding;
- opening and detecting Android Usage Access permission;
- user-controlled tracked-application selection;
- reading historical UsageStats through the native bridge;
- processing the 14 completed-day baseline/evaluation pipeline;
- generating risk and separate confidence output;
- displaying the contributing risk concepts;
- triggering and accepting a micro-intervention;
- displaying real day-level usage metrics in history/trend views.

This validates the **engineering/runtime pipeline**, not the clinical validity of DERM thresholds, behavioral efficacy, or demographic generalization.

Full engineering record: [`docs/real-device-validation-2026-09-03.md`](docs/real-device-validation-2026-09-03.md)

## Engineering case study: Android event fragmentation

### Problem

The first physical-device build reported approximately **600–880 sessions per day**. Those values were inconsistent with a user-facing definition of an application-use session.

An initial hypothesis blamed launcher/system packages. Restricting the metric to user-selected packages did **not** solve the problem, so that hypothesis was rejected after physical-device retesting.

### Root cause

Android UsageEvents can expose rapid foreground/background transitions inside one continuous application interaction. Treating every technical interval as a separate behavioral session fragmented a single interaction into many sessions.

### Correction

The collector was changed so that:

- only user-selected tracked packages contribute to the tracked-session metric;
- redundant foreground transitions do not reset an already-open interval;
- same-package intervals separated by **30 seconds or less** are grouped into one behavioral session;
- different packages are never merged;
- duration remains independently calculated from usage intervals.

The 30-second value is an engineering sessionization/debounce parameter, **not** a clinical threshold.

### Physical-device result

| Date | Raw fragmented count | Normalized count |
| --- | ---: | ---: |
| 02.09.2026 | 677 | 54 |
| 01.09.2026 | 711 | 59 |
| 31.08.2026 | 825 | 43 |
| 30.08.2026 | 880 | 33 |
| 29.08.2026 | 685 | 33 |
| 28.08.2026 | 600 | 36 |
| 27.08.2026 | 787 | 39 |

The normalized counts were approximately **92–96% lower** than the fragmented technical-event counts. This is a normalization result, not an accuracy-improvement claim.

A useful control case was 29.08.2026: tracked-social usage remained **104 minutes**, total screen time remained **207 minutes**, and sensitive-hour usage remained **3 minutes**, while session count changed from **685 to 33**. This helped verify that sessionization was being corrected without simply suppressing usage duration.

## Engineering case study: duplicate foreground duration bug

A second investigation found a separate duration-pairing problem.

The same raw UsageStats event set was replayed through alternative pairing semantics to isolate algorithm behavior from Android query variability. On two affected days, a duplicate Instagram foreground event caused duration inflation of:

- **+88 minutes** on 30.08.2026;
- **+129 minutes** on 27.08.2026.

The final implementation uses the most recent foreground timestamp for duration pairing. Duration pairing was extracted into a pure helper and a regression test was added for duplicate foreground events. Session normalization remains a separate metric and is independently tested.

## Explainable decision system

DERM (**Davranışsal Erken Risk Modeli**) is a versionable, explainable early-risk decision engine rather than an opaque diagnostic score.

- **BPI — Behavioral Persistence Index:** temporal persistence of a risk pattern.
- **SRFI — Self-Regulation Failure Index:** repeated violations of the user's own limits.
- **CVL — Contextual Vulnerability Level:** context-sensitive indicators such as sensitive-hour usage.
- **PBD — Personal Baseline Deviation:** personalization/calibration layer relative to the user's own history.

Risk states:

`LOW` · `WATCH` · `ELEVATED` · `INSUFFICIENT_DATA`

ESCAPE Window states:

`CLOSED` · `OBSERVING` · `ACTIVE` · `COOLDOWN`

Baseline states:

`CALIBRATING` · `STABLE` · `FROZEN` · `RECALIBRATING`

The current MVP weights and thresholds are **not clinically validated**. Controlled pilot data and calibration are required before making efficacy or clinical-validity claims.

## Privacy boundary

The UsageStats path is deliberately minimized.

**Processed by this data path:**

- application package name;
- foreground/background event type;
- timestamp.

**Not requested by this data path:**

- message or chat content;
- photos;
- microphone recordings;
- contact lists;
- keystrokes;
- private communication content.

UsageStats is not read before explicit consent. Users choose which applications are included in assessment.

## Architecture

```text
Android UsageStats
        ↓
Native Android Bridge
        ↓
Flutter MethodChannel
        ↓
Event / Session Normalization
        ↓
Daily Feature Engine
        ↓
Personal Baseline
        ↓
DERM
        ↓
Risk + Confidence + Explanation
        ↓
ESCAPE Window
        ↓
Micro-intervention
        ↓
Outcome Tracking / History
```

Project modules are separated by responsibility:

```text
lib/
├── core/
├── data/
├── features/
├── baseline/
├── derm/
├── escape/
├── hybrid/
├── interventions/
└── ui/

test/
├── baseline/
├── derm/
├── escape/
├── features/
├── hybrid/
└── interventions/
```

## CI and testing

Main-branch pushes and pull requests run:

```text
flutter pub get
→ flutter analyze
→ flutter test
→ flutter build apk --debug
→ upload debug APK artifact
```

The project includes regression coverage for the UsageStats duration-pairing and session-normalization defects found during physical-device testing.

Workflow: [`.github/workflows/flutter-validation.yml`](.github/workflows/flutter-validation.yml)

## Functional verification path

1. Show explicit consent and Usage Access.
2. Select applications to include in assessment.
3. Show real UsageStats-derived daily metrics.
4. Open risk and confidence output and its explanation.
5. Trigger the ESCAPE Window and show why the intervention was selected.
6. Accept the intervention and show outcome/history.
7. Close with the real-device debugging case, regression tests, and CI pipeline.

## Current limitations

The MVP intentionally does **not** claim:

- clinical diagnosis or treatment;
- clinically validated DERM weights or thresholds;
- proven behavioral-outcome efficacy;
- demographic generalization;
- longitudinal reliability;
- unrestricted AI-generated psychological advice.

Chatbot, social-network, gamification, parent/institution dashboards, multi-addiction support, and an unvalidated ML classifier are outside the current MVP scope.

## Next engineering milestone

The next stage is a controlled pilot focused on data quality, DERM threshold/weight calibration, intervention-outcome measurement, UX refinement, and a documented research/validation protocol.

Pilot specification: [`docs/derm-v0.2-pilot-spec.md`](docs/derm-v0.2-pilot-spec.md)

---

**Version:** `0.1.0+1`  
**Platform:** Android / Flutter  
**Validation:** Historical physical-device record; current automated checks are in GitHub Actions.

## Local setup

Install Flutter 3.47.7 (the CI SDK) and Android SDK with Java 17, then:

```sh
git clone https://github.com/busrabuseucar/escape-window.git
cd escape-window
flutter pub get
flutter analyze
flutter test
flutter run
```

Start on an Android emulator/device. After consent, choose usage permission or **İzin vermeden örnek verilerle dene** for an explicitly labeled synthetic scenario. A physical-device run is required to validate real UsageStats behavior. Debug builds are development artifacts, not signed production releases.

## Current operational boundaries

- Assessment uses completed historical days, not live monitoring. Seven days calibrate the baseline; seven subsequent days are evaluated.
- Onboarding choices and intervention preference are session-only and reset on restart. Intervention responses/cooldowns persist locally. Demo and device-data responses use separate storage keys.
- The intervention switch now controls the action. Deferring records a response and cooldown; it does not schedule a notification.
- Research sharing is unavailable and disabled. Android automatic backup is disabled for the app; device/OEM transfer behavior still needs device testing.
- Reset awaits local response deletion and returns to onboarding only after success. It does not delete Android UsageStats or revoke Usage Access; those are OS settings.
- Data completeness currently distinguishes empty versus nonempty event results; it does not prove full-day coverage. Boundary-crossing sessions, missing events and concurrent foreground intervals can affect totals. A nonempty day is not a guarantee of complete capture.
- Persisted outcomes use SharedPreferences, not an encrypted database. Existing legacy outcomes have no source tag; only newly separated demo records are isolated from physical-mode cooldowns.

[Technical design and verification limits](docs/TECHNICAL_DESIGN.md)
