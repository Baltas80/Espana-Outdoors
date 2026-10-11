# Mobile build baseline — 2026-10-11

## Purpose

Recover a green, reproducible mobile build baseline without weakening release checks, introducing placeholder production endpoints, or changing product behavior.

## Canonical starting point

- Repository: https://github.com/Baltas80/Espana-Outdoors
- Branch: `master`
- Baseline commit: `1d39f25783e87b7d68bb1d394461b84b4d8d7cca`
- Commit title: `Add AdMob app-ads.txt authorization`
- Commit time: 2026-10-08T18:54:47Z

## Baseline execution evidence

### GitHub Actions CI — run 37827938182, attempt 1

- Run: https://github.com/Baltas80/Espana-Outdoors/actions/runs/37827938182
- Commit SHA: `1d39f25783e87b7d68bb1d394461b84b4d8d7cca`
- Conclusion: **failure**
- Flutter job: **failure**
- Source Gateway job: success
- iOS build job: success
- Security baseline: success, run https://github.com/Baltas80/Espana-Outdoors/actions/runs/37827938223
- Web deployment workflow: success, run https://github.com/Baltas80/Espana-Outdoors/actions/runs/37827937970
- External Cloudflare Workers Builds check for the same SHA: failure; investigate separately from the GitHub Actions deploy job.

Steps in the Flutter job that completed successfully before the build failure:

- Native-project generation and Android native configuration
- CI build-profile validation
- Dependency resolution
- Map and live-data provider guards
- `flutter analyze --no-fatal-infos`
- Focused routing/offline/safety tests
- Full `flutter test --coverage --concurrency=1` suite

Failure point: **Android release build**, Gradle task `:app:processReleaseMainManifest`.

Exact error:

```text
Attribute data@scheme at AndroidManifest.xml requires a placeholder substitution
but no value for <appAuthRedirectScheme> is provided.
```

Consequences: Android APK/AAB verification, release-manifest generation and artifact upload were skipped. This baseline must not be labeled release-ready.

### GitHub Actions CI — run 37827938182, attempt 2 (rerun)

- Run attempt: https://github.com/Baltas80/Espana-Outdoors/actions/runs/37827938182/attempts/2
- Commit SHA: `1d39f25783e87b7d68bb1d394461b84b4d8d7cca`
- Conclusion: **failure**, confirming the baseline failure is reproducible.
- `flutter analyze`, focused routing/offline/safety tests and the full test suite passed again.
- Source Gateway and iOS build jobs remained successful.
- Android release failed with the same missing `appAuthRedirectScheme` Gradle placeholder at `:app:processReleaseMainManifest`; Android artifact verification and upload were skipped.


## Remediation included in this branch

1. Configure `appAuthRedirectScheme=com.espanaoutdoors` in the generated Android Gradle `defaultConfig` for both Kotlin DSL and Groovy.
2. Verify the scheme during Android native configuration, so CI fails at a focused guard rather than during Gradle manifest merge.
3. Remove the obsolete callback activity associated with the retired `openidconnect` dependency; make this cleanup idempotent.
4. Document the native configuration contract.
5. Commit the `pubspec.lock` generated on the pinned Flutter 3.47.5 runner and retain its resolved contents as CI evidence. Keep the build-fix PR focused on code and lockfile; add `--enforce-lockfile` to workflows in a follow-up after this baseline passes.

## Release baseline acceptance criteria

A commit is a validated CI baseline only when all relevant jobs and steps are green for the exact same commit SHA:

- Dependency resolution from the committed lockfile succeeds with lockfile enforcement.
- Android native configuration guard, static analysis, focused tests and full test suite pass.
- Android release APK and AAB build successfully.
- APK/AAB integrity and release-manifest verification pass; artifacts include their SHA-256 digests.
- iOS analysis, tests and no-codesign release build pass.
- Source Gateway tests pass.
- The separate security workflow passes.
- Any external build/deploy check failures are recorded separately and investigated; do not conflate them with app compilation.

## Dependency reproducibility

- A lockfile was resolved by GitHub Actions using Flutter `3.47.5` in CI run `38094153740`, then committed to this branch as `9e6754243df004af6344a0f7891def8ccdef067b`.
- The checked-in `pubspec.lock` is 35,547 bytes; GitHub blob SHA: `15695c531315a6b9d956e74097ed02020d3a9ea2`.
- Source artifact: [dart-dependency-lock-95cc0d3190187f5e426dec0cef6d4c2f74158d7e](https://github.com/Baltas80/Espana-Outdoors/actions/runs/38094153740); artifact SHA-256: `f02a0751b656449e6287ef10462e3959c25ad85d94cc370c717c8cafc202ea64`.
- This stabilization PR deliberately leaves workflow definitions unchanged so the existing CI/staging checks can validate the code fix without requiring approval of workflow-file edits. Normal `flutter pub get` consumes the committed lockfile; adding `--enforce-lockfile` is a follow-up hardening step after the baseline is green.
- The lockfile reports minimum SDK constraints Dart `>=3.13.0` and Flutter `>=3.47.0`, while `pubspec.yaml` declares lower minima. The CI target is pinned to Flutter `3.47.5`; support for the older declared minima has not been demonstrated and must not be claimed without a separate compatibility decision and test matrix.

## Evidence policy

Record each baseline or remediation run by its GitHub Actions URL, run attempt, commit SHA, conclusion, job-level outcomes and key failed step. Do not overwrite a previous result with a later rerun; preserve both attempts. Record artifact SHA-256 values from the generated manifest for successful Android release builds. Physical-device validation remains separate from CI and is not implied by a green workflow.

## Validation run coordination

- Original remediation branch: `fix/reproducible-android-baseline-20261011`, PR #90.
- Isolated validation branch: `fix/reproducible-android-baseline-validation-20261011`, PR #91.
- Reason: the earlier PR ref retained a CI run in progress with the Source Gateway job reporting no steps; newer CI/staging runs stayed pending. The validation PR records fresh checks on a distinct ref. This is an execution-coordination measure, not evidence that the build has passed.
- Do not merge either PR until CI and Android staging for the exact latest head SHA complete successfully and Android release artifacts are verified.

## Validation evidence — PR #91, first complete green run

### Tested references

- PR: [#91](https://github.com/Baltas80/Espana-Outdoors/pull/91)
- PR head SHA: `bede1f29162bd62785100c7c07f32d2496c462c8`
- Base/master SHA at test time: `1d39f25783e87b7d68bb1d394461b84b4d8d7cca`
- GitHub-generated PR merge commit used by the release manifest: `a7087d96602afed6bda2b5c3a47495a72635b674`
- Flutter SDK: `3.47.5`, stable channel
- App version: `0.1.0+5`

### Run outcomes

| Workflow | Run / attempt | Result | Evidence |
|---|---|---|---|
| CI | [38094647092 / attempt 1](https://github.com/Baltas80/Espana-Outdoors/actions/runs/38094647092) | **success** | Analyze, focused routing/offline/safety tests, full test suite, Android release build, APK/AAB verification, release manifest generation, artifact upload, coverage upload, Source Gateway and iOS build all passed |
| Android staging | [38094647190 / attempt 1](https://github.com/Baltas80/Espana-Outdoors/actions/runs/38094647190) | **success** | Native configuration guard, analysis/tests, staging APK build and verification, Android map native smoke and evidence upload passed |
| Security baseline | [38094647166 / attempt 1](https://github.com/Baltas80/Espana-Outdoors/actions/runs/38094647166) | **success** | Security workflow completed successfully |

### Release artifact evidence

The `android-release` artifact was downloaded and its manifest inspected; the manifest's APK/AAB SHA-256 values were independently recomputed from the archive contents and matched.

- [android-release artifact, ID 11684829454](https://github.com/Baltas80/Espana-Outdoors/actions/runs/38094647092/artifacts/11684829454)
  - Artifact ZIP SHA-256: `75cca6c6aba355b6c4a9c13599a5f92532ba7a90e8c7eb517bff4b22f6b42bb4`
  - APK: `app-release.apk`, 124,050,425 bytes; SHA-256: `17ee19b92c6525cbf2493a1d82ab8ad81a0a5ba3961e31fd653779fd23cd453d`
  - AAB: `app-release.aab`, 124,233,667 bytes; SHA-256: `9014aa49dc9676efdb1ae6014dffc234b83c7cb789770999d5c2832099999f4a`
- [android-staging-apk artifact, ID 11685433211](https://github.com/Baltas80/Espana-Outdoors/actions/runs/38094647190/artifacts/11685433211)
  - Artifact ZIP SHA-256: `01c6b6fb3030af9fa1f691e7af0d0ae1bd2af66b795403b6bd24ec17bccb6fe1`
- [android-map-smoke artifact, ID 11685613240](https://github.com/Baltas80/Espana-Outdoors/actions/runs/38094647190/artifacts/11685613240)
  - Artifact ZIP SHA-256: `e79e70210c8db23e5ee3c8acb0a83ded967efe3d07da190ea4ee49c3a4232656`
- [coverage artifact, ID 11685048759](https://github.com/Baltas80/Espana-Outdoors/actions/runs/38094647092/artifacts/11685048759)
  - Artifact ZIP SHA-256: `de93d7fa7d94b492351ea07c6dccf60f23940ccd4b317349db05bbce24587254`

These hashes identify the exact artifacts from these runs. Any subsequent commit must receive a fresh green CI/staging/security run before being considered the release baseline.

### Current interpretation

The AppAuth placeholder failure reproduced on the original master commit and is resolved in this tested PR merge commit. This is the first complete green Android release + staging smoke + iOS + security result on the remediation branch. It is not yet the final master baseline: the evidence update itself creates a new commit and must be validated on the resulting SHA before merge. Workflow-level `--enforce-lockfile` remains a follow-up hardening item; the committed `pubspec.lock` is currently consumed by standard `flutter pub get`, but strict enforcement has not been tested in these runs.
