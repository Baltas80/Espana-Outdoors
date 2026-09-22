# P0 Tooling Registry

| Capability | Reused component | Version | License | Scope | Production gate |
|---|---|---:|---|---|---|
| Map renderer | flutter_map | 8.3.2 | BSD-3-Clause | Flutter all platforms | Provider and attribution audit |
| Native offline raster MBTiles | flutter_map_mbtiles | 1.0.4 | MIT | Android/iOS/Linux/macOS/Windows | Archive licensing and device storage tests |
| MBTiles reader | mbtiles | 0.5.1 | BSD-3-Clause | Native runtime | Integrity and corrupted archive tests |
| HTTP transfer | Dio | 5.11.1 | MIT | Flutter platforms | TLS, cancellation, resume, retry tests |
| Hash verification | crypto | 3.0.7 | BSD-3-Clause | Flutter all platforms | SHA-256 mandatory before ready |
| Battery telemetry | battery_plus | 7.1.1 | BSD-3-Clause | Android/iOS/macOS/Web/Linux/Windows | Device capability fallback |
| Routing/elevation | Valhalla | 3.9.0 | MIT | Backend / future offline runtime | Self-hosting, data licensing, capacity |
| Gateway runtime | Shelf | 1.4.2 | BSD-3-Clause | Backend | Auth, rate limits, observability |
| Gateway router | shelf_router | 1.1.4 | Apache-2.0 | Backend | API contract and regression tests |

## Rules

1. No dependency is promoted to production solely because it is popular.
2. License, platform support, maintenance, security advisories and operational cost must be reviewed before production release.
3. Provider data licenses are separate from software licenses and must be recorded per dataset.
4. New dependencies for safety-critical paths require a replacement/fallback plan.
