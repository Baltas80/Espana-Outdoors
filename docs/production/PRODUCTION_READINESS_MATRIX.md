# España Outdoor — Production Readiness Matrix

This document separates repository-complete work from dependencies that require external infrastructure, credentials, contracts, or physical devices.

| Area | Repository | External / physical | Release gate |
|---|---|---|---|
| CI | READY | — | GREEN CI required |
| Android release | READY | Physical Android QA | Device test required |
| iOS release | READY | Physical iOS QA + Apple account | Device/store validation required |
| LAND visual pack | LAND-01..04 present | Remaining pack | Asset integration + QA |
| PMTiles | Integration ready | R2/HTTPS + real Spain PMTiles | Range + online/offline test |
| Offline catalog | Release variable wired | Real catalog endpoint | Endpoint health + offline test |
| Valhalla | Integration ready | Production routing host | E2E routing test |
| Live Data | Gateway ready | Provider credentials/API | Live-data smoke test |
| Rescue Link | Integration/CI ready | Production deployment/domain | E2E safety test without real 112 call |
| Contracts | Matrix documented | Accounts/contracts must exist | Evidence recorded before production |
| Stores | Build pipeline ready | Google Play / Apple Developer | Final QA + signing + submission |

## Rules

1. Never substitute invented production URLs or credentials.
2. Never mark an external service production-ready from a successful unit test alone.
3. Never perform a real 112 emergency call for testing; use controlled mocks/sandboxes.
4. A release candidate must contain only production configuration supplied through the release environment.
5. Physical Android/iOS validation remains a separate gate from CI.

## Visual asset rule

The Flutter asset declaration includes `assets/backgrounds/` and `assets/landscapes/`. LAND-01 is the Home hero direction. SVG assets are rendered with `flutter_svg`; controls are not baked into the artwork.
