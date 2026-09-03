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

## Session-count finding

The first device build reported daily session counts in the approximate 600–880 range. Code inspection showed that the collector used every paired foreground/background session on the device for `sessionCount`. Android UsageEvents may include launcher/system components and frequent app transitions, so this value can represent device-level foreground transitions rather than sessions of the applications explicitly selected for assessment.

### Correction

`sessionCount` is now calculated only from sessions whose package is included in `trackedSocialPackages`. `meanSessionDurationMinutes` uses the same scope (`socialMediaTimeMinutes / tracked session count`).

Total screen-time and sensitive-hour calculations remain device-level metrics. The change therefore corrects the meaning of the session metric without changing the current DERM risk calculation path, which does not directly consume `sessionCount`.

## Privacy observations

The tested bridge requested only Android Usage Access. The native payload contained application package name, foreground/background event type and timestamp. No message text, photo content, microphone input, keystrokes or private communications were requested by this data path.

## Validation status

**Physical-device MVP runtime chain: PASS**

This is an engineering/runtime validation. Clinical validity, threshold calibration, behavioral outcome efficacy, demographic generalization and longitudinal reliability require separate pilot studies and validation protocols.
