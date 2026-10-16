# Technical Design and Verification Limits

The pipeline separates Android event collection, duration pairing, session normalization, daily features, baseline, DERM, escape-window gates and intervention outcomes. Rule thresholds are engineering parameters, not clinically validated measurements.

## October corrections

- Demo entry is available without OS usage permission, after consent; the dashboard explicitly labels its data source.
- Intervention preference is passed from application state to the privacy screen and checked before opening a recommendation. Research-sharing controls cannot enable a nonexistent service.
- Local deletion is awaited; failed storage operations surface errors instead of claiming success.
- Demo response storage is separated from physical-mode response storage. Legacy records cannot be retrospectively classified.
- Calendar boundaries use local calendar constructors instead of fixed 24-hour subtraction/addition across daylight-saving changes.
- Automatic Android backup is disabled to reduce unintended export of local response metadata.
- Main-branch changes trigger analysis, tests and a debug APK build.

- Missing-capture days are excluded from baseline means and calibration-day counts; absence is not zero use.
- Onboarding cannot enable unimplemented notification delivery.

## Open verification work

A new physical-device run is necessary for permission revocation, app restarts, usage-event coverage, DST days, small screens, OEM backup/transfer behavior and intervention response persistence. Historical device results in the September report are not evidence that October modifications were physically retested. SharedPreferences is not encrypted or transactional; multi-screen concurrent writes are not a supported workflow. No background monitoring or notification scheduler is implemented.
