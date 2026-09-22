# España Outdoor — Design System v0.1

## Brand promise

**Explora España. Hazlo preparado.**

España Outdoor is positioned as a premium outdoor intelligence platform, not as a generic hiking catalogue. The visual system combines nature, exploration, technology and safety without tourism clichés, military styling or excessive visual effects.

## Core identity

- **Primary mark:** compact relief/path symbol with a restrained solar accent.
- **Wordmark:** ESPAÑA OUTDOOR, uppercase, strong spacing, contemporary sans-serif.
- **Personality:** precise, calm, capable, human and outdoors-oriented.
- **Avoid:** literal Spanish flag as logo, generic mountain silhouettes, glossy gradients, 3D effects, childish wildlife mascots and government-like visual language.

## Colour tokens

| Token | Hex | Role | Contrast guidance |
|---|---|---|---|
| Forest | `#145A43` | Primary brand / actions | Primary light UI colour |
| Forest Light | `#43B982` | Dark-mode primary | Primary dark UI colour |
| Earth | `#B38A55` | Secondary / terrain | Decorative or dark-surface use; not small text on light |
| Earth Light | `#E5C18A` | Dark-mode secondary | Decorative or dark-surface use |
| Sun | `#F2A11A` | Accent / discovery | Never use as small text on white |
| Water | `#2E86A8` | Water / information | Use with sufficient text contrast |
| Water Light | `#8EC9E5` | Dark-mode information | Use on dark surfaces |
| Rock | `#687280` | Neutral / terrain | Secondary text only where contrast is sufficient |
| Light Background | `#F5F7F4` | Light canvas | Default light canvas |
| Dark Background | `#0A1713` | Dark canvas | Default dark canvas |
| Text Light | `#10231E` | Primary light text | High contrast |
| Text Dark | `#E8F0ED` | Primary dark text | High contrast |

### Semantic states

- **SUCCESS:** `#137A4B`
- **INFORMATION:** `#176B87`
- **PRECAUCIÓN:** `#F2A11A`
- **PELIGRO:** `#B42318`
- **EMERGENCIA:** `#C62828`

Semantic states must never rely on colour alone. Pair colour with label, icon and/or text.

## Modes

### Light

Warm off-white canvas, white surfaces, forest primary, earth/water supporting colours and dark green text.

### Dark

Deep forest-black canvas, elevated dark-green surfaces, light forest primary and high-contrast text.

### High contrast

Use the same semantic vocabulary while increasing surface separation, outlines and text contrast. Avoid using the accent yellow as text.

## Typography

Target family: **Montserrat** or a metrically comparable contemporary sans-serif. The production app should bundle the selected font files so typography remains deterministic offline and across platforms. Do not depend on runtime font downloads in the final release.

Recommended hierarchy:

- Display: 32–40 px / 800
- H1: 28–32 px / 800
- H2: 22–26 px / 800
- Section: 18–20 px / 700
- Body: 15–17 px / 400–500
- Label: 13–14 px / 600–700
- Map/status microcopy: minimum 12 px, with sufficient contrast

## Shape and spacing

- Base spacing unit: **4 px**.
- Standard screen gutter: **20 px** mobile, **24–32 px** tablet/desktop.
- Cards: 20 px radius.
- Controls: 14–16 px radius.
- Touch targets: minimum 48 × 48 logical px.
- Use elevation sparingly; prefer contrast and borders over shadows.

## Iconography

Icons use a restrained outline language with consistent stroke weight, rounded joins and simple silhouettes. Emergency and safety icons may use filled forms when faster recognition is required.

Required semantic families include navigation, terrain, route, activity, weather, hazard, services, emergency, GPS, offline, GPX, conservation and wildlife.

Wildlife is represented as information, never as a mascot system.

## Map visual language

The map is a primary product surface, not a decorative background.

Layer hierarchy:

1. Basemap / terrain
2. Primary route
3. Secondary trails
4. User position and heading
5. Services / POI
6. Water / shelters / access
7. Restrictions and hazards
8. Live alerts
9. Emergency overlays

Recommended route colours should remain distinct from semantic danger colours. Red is reserved for actual danger/emergency semantics.

## Safety hierarchy

`INFORMACIÓN → PRECAUCIÓN → PELIGRO → EMERGENCIA`

SOS is persistent and recognisable but must not visually dominate normal navigation. Emergency actions must use explicit labels and confirmation patterns appropriate to the action.

## Rescue Link

Rescue Link uses the same forest identity with a dedicated chain/link motif. It must remain visually distinct from the official emergency channel and must always state whether the recipient is an official service, trusted contact, verified collaborator or nearby volunteer.

## Photography

Photography should show real Spanish landscapes and outdoor activity without tourism staging. Prioritise natural light, realistic weather, environmental texture, human scale and geographic diversity.

Do not fabricate official hazard conditions or imply that a photograph represents current conditions.

## Responsive behaviour

- **Mobile:** bottom navigation, compact controls, map-first interaction.
- **Tablet:** split view where useful; persistent route/detail context.
- **Desktop/Web:** navigation rail or sidebar, larger map canvas, multi-column detail layouts.
- **Wearables:** high contrast, large targets, minimal information and critical alerts only.

## Accessibility

The visual system targets WCAG 2.2 AA for normal product surfaces. Critical safety information should target stronger contrast where practical. Never encode a status using colour alone.

## Brand governance

New components must reuse these tokens. Feature teams must not introduce arbitrary colours, corner radii or icon styles. New semantic states require product and safety review before implementation.
