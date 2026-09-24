# España Outdoor — Visual Asset Status

## Verified in `master`

- `assets/landscapes/picos_europa.jpg`
- `assets/backgrounds/bg_home.svg`
- `assets/backgrounds/bg_map.svg`
- `assets/backgrounds/bg_navigation.svg`
- `assets/backgrounds/bg_offline.svg`
- `assets/backgrounds/bg_profile.svg`
- `assets/backgrounds/bg_rescue.svg`
- `assets/backgrounds/bg_routes.svg`
- `assets/backgrounds/bg_safety.svg`

## Photographic pack

The intended photographic pack is defined as BG-01 through BG-10 plus the landscape/flora/fauna/editorial libraries.

The JPG photographic pack must not be marked as integrated until each binary is physically present in GitHub and referenced by the Flutter asset configuration. Generated or locally available images are not considered repository assets until verified on `master`.

## Design rule

BG-01 is the fixed Home hero: a real-looking outdoor scene with a man and his dog walking a Spanish trail, viewed naturally from behind or in profile. It must communicate exploration, nature, companionship, adventure and freedom, without looking like a posed stock-photo portrait.

## Integration gate

1. Binary exists in GitHub.
2. Flutter asset declaration exists.
3. Image loads in the intended screen.
4. Text and controls remain readable over the image.
5. Light/dark contrast is acceptable.
6. Mobile memory/performance is acceptable.
7. Android and iOS CI pass after integration.
