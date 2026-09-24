# España Outdoor — Visual Asset Status

## Verified in `master`

### Landscape pack
- `assets/landscapes/picos_europa_land01.svg` — LAND-01
- `assets/landscapes/pirineos_land02.svg` — LAND-02
- `assets/landscapes/sierra_nevada_land03.svg` — LAND-03
- `assets/landscapes/ordesa_land04.svg` — LAND-04

### Background pack
- `assets/backgrounds/bg_home.svg`
- `assets/backgrounds/bg_map.svg`
- `assets/backgrounds/bg_navigation.svg`
- `assets/backgrounds/bg_offline.svg`
- `assets/backgrounds/bg_profile.svg`
- `assets/backgrounds/bg_rescue.svg`
- `assets/backgrounds/bg_routes.svg`
- `assets/backgrounds/bg_safety.svg`

## Home integration

The Home hero now references `LAND-01` directly:

`assets/landscapes/picos_europa_land01.svg`

The superseded raster placeholder `picos_europa.jpg` has been removed to prevent ambiguous asset selection.

The visual itself contains no application controls, buttons or navigation. UI is layered by Flutter independently.

## Design rule

BG-01 remains the fixed Home background direction: a natural outdoor scene communicating exploration, nature, companionship, adventure and freedom. The image must read as a real situation rather than a posed portrait.

## Integration gate

1. Asset exists in GitHub.
2. Flutter asset declaration exists.
3. Intended screen references the correct asset.
4. Text and controls remain readable over the image.
5. Light/dark contrast is acceptable.
6. Mobile memory/performance is acceptable.
7. Android and iOS CI pass after integration.

## Next visual work

Continue with LAND-05 onward, then the dedicated flora/fauna/editorial library. Binary photographic assets are only considered repository-ready after being physically committed and verified on `master`.
