# Gitleaks baseline exceptions

This repository is scanned with Gitleaks against the full Git history. The root-level `.gitleaksignore` contains exact fingerprints for findings reviewed on 2026-10-13. It does not exclude whole files, rules, branches, or commit ranges.

| Fingerprint origin | Classification | Rationale and disposition |
|---|---|---|
| `236f226d64da127b11a9aadb7d424574a7fb837a` and `53c1901bd9b24ae4c5455a68af095ef90c33fa70` | Historical OIDC adapter `generic-api-key` | The detections are a fixed client-side compatibility value passed to the old `openidconnect` adapter, not a provider-issued API credential. The adapter was retired in commit `587a179d901cd0d749d420999465f6c9d0cd1e3f`; the current file is only an empty compatibility library and `openidconnect` is not a current dependency. Do not reuse the old value as a cryptographic secret. If any distributed build persisted real user tokens using that retired adapter, separately assess token/session invalidation and migration. |
| `7d9c0f2939a11b691e949184eb738226d0968a2e` | Expired signed hero-image URL (`jwt`) | The homepage previously embedded a temporary signed CloudFront image URL. Its embedded expiry was 2026-09-29 23:01:40 UTC. The current homepage now uses a non-signed Unsplash URL; the old history entry remains in Git and is ignored by its exact fingerprint only. |
| `7f6398a4aae9335a32bcbe3fa7fa41f930b6d092` | Waypoint preference key (`generic-api-key`) | `_storageKey` is a local SharedPreferences namespace, not an authentication credential or access token. |
| `33c3ab2cc3f8cd9a1339c370d23a44c20e93df2f` | Example environment placeholder (`generic-api-key`) | The finding came from a documented placeholder in `infra/.env.example`, not a deployed value. The current example uses `SET_IN_SECRET_MANAGER`. |

## Maintenance rules

- Never add broad path, regex, rule, or commit-wide allowlists just to make CI green.
- Add a fingerprint only after reviewing the original line, usage, and whether a credential is active.
- If a provider-issued credential or a production secret is found, revoke/rotate it first; removing it from the latest tree does not remove it from Git history.
