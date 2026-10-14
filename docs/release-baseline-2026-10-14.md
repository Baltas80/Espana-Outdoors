# Release baseline evidence — 2026-10-14

## Scope and immutable source revision

- Repository: `Baltas80/Espana-Outdoors`
- Default branch: `master`
- Source commit: `e175e673758cc69e728bbcfaff523ec7d7e46ed4`
- Commit URL: https://github.com/Baltas80/Espana-Outdoors/commit/e175e673758cc69e728bbcfaff523ec7d7e46ed4
- Captured: 2026-10-14
- Purpose: record the available CI evidence before further baseline or production-readiness changes.

This document is a snapshot, not a claim that every production acceptance gate has passed. Re-run checks after any code, dependency, native configuration, data or release configuration change.

## GitHub Actions evidence for the source commit

All runs below report `status=completed` and `conclusion=success` in GitHub Actions at the time of capture.

| Workflow | Run ID | Result | Evidence |
| --- | ---: | --- | --- |
| CI | 38561872373 | PASS | https://github.com/Baltas80/Espana-Outdoors/actions/runs/38561872373 |
| Android staging | 38561872588 | PASS | https://github.com/Baltas80/Espana-Outdoors/actions/runs/38561872588 |
| Security baseline | 38561872422 | PASS | https://github.com/Baltas80/Espana-Outdoors/actions/runs/38561872422 |
| Deploy España Outdoor Web | 38561872394 | PASS | https://github.com/Baltas80/Espana-Outdoors/actions/runs/38561872394 |
| Public PMTiles verifier tests | 38561872491 | PASS | https://github.com/Baltas80/Espana-Outdoors/actions/runs/38561872491 |

### CI job breakdown

The main CI run completed successfully for these jobs:

- `source-gateway`
- `flutter` — includes dependency resolution under the committed lockfile, Dart analysis, focused routing/offline/safety tests, full Flutter test suite, Android APK and App Bundle release builds, and release asset verification according to `.github/workflows/ci.yml`.
- `ios-build`
- `pmtiles-input-validation`

Security baseline jobs completed successfully:

- Secret scan
- SBOM generation
- CodeQL for GitHub Actions
- Dart static analysis fallback
- Dependency audit
- Filesystem scan
- Open Graph image policy
- CodeQL for Go

The Android staging workflow completed successfully, including its Android emulator map-native smoke step (`tool/smoke_android_map.sh ... online`) and upload of logcat, window hierarchy and screenshot evidence. This establishes an emulator-based online map smoke only; it is not equivalent to physical-device testing or offline end-to-end acceptance. GPS, background recording, offline maps, navigation and SOS still require the relevant field/device checks.

## Artifacts retained by GitHub Actions

At capture time, the following artifacts were available and had not expired:

| Workflow run | Artifact | Size | Artifact ID |
| --- | --- | ---: | ---: |
| CI — 38561872373 | `android-release` (APK/AAB bundle) | 210,362,935 bytes | 11892953589 |

GitHub artifact metadata reports SHA-256 digest `f9108a53a736b2c4ad2543f7dbe2cd5a45d9d70834539c968ab902f03fd533a0` for the `android-release` archive. This is the archive digest reported by GitHub, not a separately calculated digest for each APK/AAB inside it.
| CI — 38561872373 | `coverage` | 9,182 bytes | 11892908659 |
| Android staging — 38561872588 | `android-staging-apk` | 86,656,098 bytes | 11893282727 |
| Android staging — 38561872588 | `android-map-smoke-38561872588` | 1,901,436 bytes | 11892379090 |

Artifacts are downloadable from their respective run pages while GitHub retains them. Their existence is not proof that a physical-device field test has passed. Before release, extract and preserve the APK/AAB, calculate independent SHA-256 digests and tie them to the source commit and build metadata.

## Production acceptance still outstanding

1. **Live public PMTiles integrity:** the new verifier has automated unit tests, but the full live-object check has not been evidenced here. The documented operation downloads the complete map (about 1.27 GB) and verifies exact byte count and SHA-256.
2. **Physical-device QA:** GPS accuracy, background/foreground transitions, battery impact, Android permission flows, offline package install/resume, and navigation behavior need device-based acceptance tests.
3. **Offline end-to-end acceptance:** verify download, checksum, storage, map rendering, route guidance and failure/recovery with connectivity disabled.
4. **SOS / Rescue Link operational acceptance:** verify permission denial, unavailable connectivity, expired/invalid links, privacy behavior and clear user-facing limitations. Do not represent these flows as a guaranteed emergency service.
5. **Production services and secrets:** CI success does not prove that production Valhalla, map catalog/R2, OIDC, RevenueCat or Sentry runtime configuration is valid in the deployed environment.
6. **Release provenance:** preserve APK/AAB, SHA-256 values, Flutter/toolchain versions and test evidence for each release candidate.

## Operational rule

Do not provision or republish infrastructure just to re-check a service that is already configured. Verify current state first. Do not promote a release solely because CI is green; production acceptance must include the gates above that apply to the candidate.

## Next recommended sequence

1. Download and archive the APK/AAB artifacts from the successful CI run; calculate independent SHA-256 digests for the extracted APK and AAB and record their exact filenames and build metadata.
2. Run the live PMTiles integrity gate against the current public catalog and record the actual output and timestamp.
3. Install the candidate on a physical Android device and execute a documented smoke checklist, including offline operation and route recording.
4. Record defects with reproducible steps; fix them on isolated branches and rerun CI.
5. Only after the evidence is complete, decide whether the revision is an acceptable release baseline.
