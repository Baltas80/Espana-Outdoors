# España Outdoor — Physical QA Gate

This gate is intentionally separate from CI. A passing GitHub Actions build does not prove device behaviour.

## Android release artifact

- Build source: `master` production CI
- Required artifact: `app-release.apk`
- Required checks: install, cold start, permissions, map/GPS, route calculation, guidance, offline region, SOS flow, Rescue Link, background behaviour.

## iOS release build

- CI gate: iOS Release build without code signing
- Required physical checks: install from a signed development/distribution build, launch, permissions, map/GPS, routing, offline, navigation, SOS, Rescue Link and background behaviour.

## Safety test rule

Never place a real emergency call as part of ordinary QA. Validate the emergency UI, permissions, intent/hand-off and local safety behaviour without contacting 112 unless an authorised controlled test has been arranged.

## Evidence required before release-store gate

For each platform record:

1. device model;
2. OS version;
3. app build/version;
4. GPS permission result;
5. map online result;
6. map offline result;
7. route calculation result;
8. navigation/guidance result;
9. SOS/112 hand-off result;
10. Rescue Link result;
11. background/screen-off result;
12. screenshots or screen recording for any failure;
13. reproducible steps for every defect.

A platform is not considered QA-complete until all mandatory checks pass or an explicit release-blocking exception is documented.
