# ESCAPE Window AI — Real Device Validation

**Date:** 03.09.2026  
**Platform:** Android  
**Build:** GitHub Actions debug APK  
**Scope:** End-to-end MVP runtime validation with Android UsageStats

## Objective

Validate that ESCAPE Window AI can move beyond demo data and execute its core pipeline on a physical Android device using real UsageStats events while preserving the MVP's privacy-minimized design.

## Successfully validated flow

1. Debug APK built by GitHub Actions was downloaded and installed on a physical Android device.
2. The onboarding consent screen rendered correctly and required explicit consent before continuing.
3. The app opened Android's Usage Access settings successfully.
4. After Usage Access was granted, returning to the app was detected automatically and onboarding continued.
5. The user selected tracked applications for the assessment.
6. ESCAPE read completed-day Android UsageStats events through the native MethodChannel bridge.
7. The app produced daily behavioral snapshots from historical device usage.
8. The 14 completed-day pipeline executed, separating baseline calibration and current evaluation windows.
9. The dashboard produced an explainable early-risk state with separate confidence information.
10. The risk detail screen explained the contributing BPI, SRFI, PBD and safety-layer concepts.
11. The ESCAPE Window intervention screen selected a micro-intervention and displayed why it was triggered.
12. The user accepted the intervention and the application recorded the action flow successfully.
13. The history/trend screen displayed day-level real UsageStats-derived metrics.

## Observed runtime output

During the validation session, the application displayed real daily values including total screen time, tracked social/digital usage, sensitive-hour usage, target exceedance and data completeness.

The runtime risk output was `ELEVATED`/"Yükselmiş" with medium confidence. This observation confirms pipeline execution only; it is not a clinical validation of DERM thresholds or weights.

## Session-count investigation and correction

### Initial observation

The first physical-device build reported session counts between approximately 600 and 880 per day. These values were inconsistent with a user-facing interpretation of a behavioral application-use session.

The first correction limited session metrics to packages explicitly selected by the user. Physical-device retesting showed that this was insufficient: the same historical days still produced the inflated counts. This disproved the initial assumption that launcher/system packages were the sole cause.

### Root cause model

Android UsageEvents can expose rapid foreground/background transitions within the same application. Treating every paired transition as an independent behavioral session fragments one continuous user interaction into many technical event intervals.

### Sessionization rule

The collector now distinguishes raw usage intervals from behavioral session episodes:

- only user-selected tracked packages contribute to the tracked session metric;
- redundant foreground state transitions are not allowed to reset an already-open foreground interval;
- intervals from the same package separated by 30 seconds or less are grouped into one behavioral session episode;
- intervals from different packages are not merged;
- duration metrics remain independently derived from usage intervals so session normalization is not intended to suppress recorded usage time.

The 30-second value is an engineering debounce/sessionization parameter for short Android event fragmentation, not a clinical threshold or behavioral-risk cutoff.

### Physical-device retest

After uninstalling the previous build and performing a clean installation of the normalized build, the same historical period was measured again.

| Date | Previous session count | Normalized session count |
| --- | ---: | ---: |
| 02.09.2026 | 677 | 54 |
| 01.09.2026 | 711 | 59 |
| 31.08.2026 | 825 | 43 |
| 30.08.2026 | 880 | 33 |
| 29.08.2026 | 685 | 33 |
| 28.08.2026 | 600 | 36 |
| 27.08.2026 | 787 | 39 |

The normalized values are therefore approximately 92–96% lower than the raw fragmented-event counts.

A particularly useful control observation was 29.08.2026: tracked social usage remained 104 minutes while session count changed from 685 to 33. Total screen time remained 207 minutes and sensitive-hour usage remained 3 minutes. This supports the interpretation that the correction addressed session fragmentation rather than simply reducing usage duration.

### Duration-pairing investigation

A follow-up diagnostic build replayed the exact same raw UsageStats event set through both pairing semantics. This isolated algorithm behavior from Android query variability.

On 30.08.2026 the old/desired duration pairing produced 296 total minutes and 162 tracked-social minutes, while the earliest-foreground-preserving variant produced 384 / 250 minutes. The entire +88 minute difference came from Instagram. On 27.08.2026 the corresponding difference was +129 minutes, again entirely attributable to Instagram.

Both problem days contained one duplicate tracked foreground event for Instagram. Days without that condition remained unchanged or differed only by rounding-level noise. The final MVP therefore uses the most recent foreground timestamp for duration pairing, while keeping the 30-second same-package session normalization as a separate behavioral-session metric.

The current DERM risk path does not directly consume `sessionCount`, so this correction primarily improves measurement semantics, history presentation and future feature reliability rather than artificially changing the current risk classification.

## Privacy observations

The tested bridge requested only Android Usage Access. The native payload contained application package name, foreground/background event type and timestamp. No message text, photo content, microphone input, keystrokes or private communications were requested by this data path.

## Validation status

**Physical-device MVP runtime chain: PASS**  
**Tracked-app session normalization physical-device retest: PASS**  
**27.08 / 30.08 duration-pairing root cause: CLOSED / PASS**

This is an engineering/runtime validation. Clinical validity, threshold calibration, behavioral outcome efficacy, demographic generalization and longitudinal reliability require separate pilot studies and validation protocols.


## Final MVP cleanup — 04.09.2026

- Diagnostic-only UsageStats fields were removed from the user-facing history screen.
- Duration pairing was extracted into a pure helper and covered by a regression test for duplicate foreground events.
- Session normalization remains independently covered by unit tests.
- Final CI is required to pass static analysis, unit tests, and Android debug APK build before the cleaned MVP APK is distributed.
