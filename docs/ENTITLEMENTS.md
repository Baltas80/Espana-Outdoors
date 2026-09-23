# España Outdoor — Free / Premium / Professional

Entitlements are the only product capability boundary. Product identifiers, prices and store-specific SKUs must never be embedded in feature code.

| Capability | Free | Premium | Professional |
|---|:---:|:---:|:---:|
| Route discovery/planning | ✓ | ✓ | ✓ |
| GPS recording | ✓ | ✓ | ✓ |
| GPX import/export | ✓ | ✓ | ✓ |
| Basic offline maps | ✓ | ✓ | ✓ |
| Advanced offline areas | — | ✓ | ✓ |
| Live weather | ✓ | ✓ | ✓ |
| Live route status | ✓ | ✓ | ✓ |
| Basic route safety | — | ✓ | ✓ |
| Advanced safety analysis | — | ✓ | ✓ |
| Pet Mode | — | ✓ | ✓ |
| Fauna guide | — | ✓ | ✓ |
| Trusted contacts | ✓ | ✓ | ✓ |
| Advanced alerts | — | ✓ | ✓ |
| Natura Protect | — | — | ✓ |
| Rescue Link | — | — | ✓ |
| Professional datasets | — | — | ✓ |
| Advanced analytics | — | — | ✓ |
| API access | — | — | ✓ |
| Priority support | — | — | ✓ |

## RevenueCat mapping

Recommended entitlement identifiers:

- `free`
- `premium`
- `professional`

The backend must remain authoritative for server-side access control. RevenueCat is the subscription/entitlement source, not the authorization system for emergency operations.

## Safety exception

Emergency calling, access to 112 information, basic location display and other legally/safety-critical functions must never be paywalled in a way that could obstruct a genuine emergency.
