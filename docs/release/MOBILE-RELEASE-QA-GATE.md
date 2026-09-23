# Mobile release QA gate

This checklist is the final evidence gate after CI builds the Android and iOS artifacts. A green CI run is necessary but is not sufficient for a public release.

## 1. Functional matrix

Run on at least one supported Android device and one supported iPhone/iPad.

### Core navigation
- App cold start, warm start and resume from background.
- Home, Explore, Routes, Map, Navigation, Safety, Offline, Profile.
- Route creation with real Valhalla endpoint.
- GPX import/export.
- Start/stop/resume route recording.
- Navigation with good GPS.
- Poor GPS state.
- Off-route state.
- Arrival state.
- Backend unavailable: no fabricated route or instruction.
- Network loss during navigation/recording.
- Device restart during a recoverable recording session.

### Offline maps
- Catalog unavailable.
- Catalog entry rejected for bad licence/checksum.
- Download start/progress.
- Pause.
- App restart while paused/downloading.
- Resume.
- Corrupted package rejected.
- Verified package promoted to ready.
- Updated package replaces previous version.
- Delete removes current and superseded artifacts.
- Low-storage failure path.

### Safety / emergency
- Location services disabled.
- Permission denied and denied forever.
- 112 handoff on physical devices.
- GPS accuracy included in snapshot.
- Battery/connectivity captured in snapshot.
- Trusted-contact share uses approximate coordinates only.
- Emergency share expiry.
- Rescue Link create/accept/revoke/expire.
- No exact coordinates in public preview.
- Volunteer role never receives exact coordinates.
- Dangerous-dispatch blocks are enforced by backend policy.

### Live data
- Source Gateway authenticated access.
- AEMET current/aging/stale/unavailable states.
- Gateway unavailable.
- OIDC unavailable.
- AEMET credential expired/rotated.
- Rate limit response.
- Provenance/attribution shown where the UI consumes official data.

## 2. Accessibility
- all interactive controls have an accessible label;
- focus order is logical;
- text remains readable at increased system font scale;
- touch targets are at least 48dp where practical;
- color is never the only carrier of risk/state;
- emergency actions are visually and semantically distinct;
- map controls have accessible labels;
- loading, empty, offline and error states are understandable;
- contrast is checked in light, dark and high-contrast configurations.

## 3. Outdoor readability
Test direct sunlight, high brightness and motion:
- route line remains distinguishable from map;
- next maneuver state remains legible while moving;
- emergency primary actions remain obvious;
- no critical value depends on subtle color differences.

## 4. Performance / battery
Measure on physical devices:
- cold start time;
- map first-render time;
- route calculation latency;
- offline package installation time;
- memory while navigating;
- battery drain during a 60-minute recording;
- behavior when the OS throttles background execution.

Record device model, OS version, build commit and measurement method.

## 5. Privacy / security
Before release:
- no production secrets in APK/AAB/IPA;
- no provider API key in Flutter artifacts;
- no exact emergency coordinates in normal logs;
- no exact location in public Rescue Link preview;
- location permissions are requested only for features that need them;
- background location behavior matches the declared product policy;
- retention/expiry behavior has been exercised against the real backend;
- dependency/security/SBOM workflows are green.

## 6. Release artifacts
Android:
- release APK and AAB built by CI;
- signing verified with the release keystore;
- versionCode/versionName recorded;
- Play Integrity / signing configuration verified in the target Play Console.

iOS:
- release archive built from the intended commit;
- signing certificate and provisioning profile verified;
- bundle identifier/app capabilities verified;
- App Store Connect build uploaded from the intended commit.

For both platforms, record:
- Git commit SHA;
- artifact SHA-256;
- build date;
- Flutter/Dart version;
- native platform build version;
- release environment variables supplied through CI/secret management.

## 7. External production dependencies
The release record must identify the concrete production instances for:
- Source Gateway;
- AEMET credentials and expiry date;
- Valhalla HTTPS endpoint and Spain tile artifact;
- licensed offline map catalog/provider;
- Keycloak realm/client/role assignments;
- Rescue Link PostgreSQL;
- RevenueCat app stores/entitlements;
- Sentry DSN/project.

No placeholder endpoint may be used for a production release.

## 8. Go / no-go evidence
A release is blocked when any of the following is missing:
- CI analysis/tests;
- Android/iOS release build;
- security baseline;
- real-device emergency gate;
- real-device offline navigation gate;
- licensed map provider evidence;
- live gateway integration evidence;
- routing smoke test against the controlled Valhalla service;
- signing/store configuration;
- privacy/retention verification.

CI success must never be interpreted as evidence that external infrastructure or physical emergency behavior was tested.
