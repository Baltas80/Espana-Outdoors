# España Outdoor — Parallel Delivery Roadmap

The project is developed in parallel tracks so no major capability waits for another track to finish.

## Track A — Product & UX
- premium responsive design system
- home/discovery
- route detail
- navigation HUD
- offline download flow
- safety center
- pet mode
- wildlife guidance
- emergency UX

## Track B — Maps & GIS
- provider abstraction
- OSM-compatible attribution
- route overlays
- GPX import/export
- offline region model
- elevation/profile model
- geospatial caching

## Track C — Official data
- AEMET adapter
- wildfire/disaster adapters
- protected-area and environmental data
- provenance/freshness model
- stale-data safeguards

## Track D — Safety
- GPS health
- battery/connectivity status
- SOS flow
- 112 handoff
- trusted contacts
- temporary location sharing
- Rescue Link anti-abuse controls

## Track E — Nature & pets
- pet profiles
- route compatibility
- heat/water/shade factors
- wildlife encounter guidance
- sensitive habitat protection
- conservation-aware recommendations

## Track F — Platform
- Android
- iOS/iPadOS
- Web
- Windows
- macOS
- Linux
- platform-specific permission adapters

## Track G — Security & privacy
- secure local storage
- permission minimization
- retention matrix
- audit events
- threat model
- dependency/SBOM controls

## Track H — Quality & delivery
- unit/integration/e2e tests
- CI/CD
- static analysis
- dependency scanning
- performance/battery tests
- release checklist

## Delivery rule
A track may use mock adapters or deterministic local fixtures while upstream credentials/data feeds are unavailable. Production integration must never be faked as live data.
