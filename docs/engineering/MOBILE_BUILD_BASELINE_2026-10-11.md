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

## Remediation included in this branch

1. Configure `appAuthRedirectScheme=com.espanaoutdoors` in the generated Android Gradle `defaultConfig` for both Kotlin DSL and Groovy.
2. Verify the scheme during Android native configuration, so CI fails at a focused guard rather than during Gradle manifest merge.
3. Remove the obsolete callback activity associated with the retired `openidconnect` dependency; make this cleanup idempotent.
4. Document the native configuration contract.
5. Retain the resolved `pubspec.lock` as a CI artifact for each run, so the lockfile can be committed and dependency resolution can be enforced rather than regenerated silently.

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

## Dependency reproducibility caveat

The baseline commit does not track `pubspec.lock`. Therefore its caret-constrained Dart dependencies are not fully frozen in Git, even though CI pins Flutter to `3.47.5`. This branch adds a short-retention CI artifact for the resolved lockfile so the exact resolution can be captured. Before claiming reproducibility, commit that file and update application build workflows to use `flutter pub get --enforce-lockfile`.

## Evidence policy

Record each baseline or remediation run by its GitHub Actions URL, run attempt, commit SHA, conclusion, job-level outcomes and key failed step. Do not overwrite a previous result with a later rerun; preserve both attempts. Record artifact SHA-256 values from the generated manifest for successful Android release builds. Physical-device validation remains separate from CI and is not implied by a green workflow.
