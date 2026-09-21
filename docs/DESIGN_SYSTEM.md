# España Outdoor — Design System v0.1

## Brand direction

The visual system must feel premium, practical and recognisable outdoors. Nature is the context; technology is the instrument; safety is a core promise.

## Base palette

- Forest: `#0D3B2E`
- Spanish Red: `#AA151B`
- Spanish Gold: `#F1BF00`
- Charcoal: `#111716`
- Off White: `#F5F3ED`

Red and gold are accents. They must not turn the product into a literal flag treatment.

## Semantic colors

- Success: accessible green derived from the forest family.
- Warning: gold/amber.
- Danger: Spanish red.
- Information: neutral blue with sufficient contrast.
- Disabled: neutral gray.

Exact semantic values must be validated against WCAG contrast requirements before production lock.

## Surfaces

Use calm, high-contrast surfaces with restrained elevation. Avoid excessive glassmorphism and decorative gradients that reduce readability outdoors.

## Typography

Use a modern sans-serif with strong numeric legibility for distances, elevation, coordinates and emergency information. Typography must remain readable in sunlight and during movement.

## Components

Core reusable components should include:

- Outdoor app bar
- Bottom navigation
- Map controls
- Route card
- Route statistic
- Hazard card
- Official alert card
- Offline package card
- Weather summary
- Pet suitability indicator
- Wildlife notice
- SOS action
- Rescue Link action
- Trusted contact card
- Source/provenance badge
- Freshness indicator
- Permission explanation

## State design

Every important component needs explicit states:

- normal
- loading
- empty
- error
- offline
- stale data
- permission denied
- degraded location
- emergency

## Accessibility

- Touch targets should be suitable for one-handed outdoor use.
- Never communicate danger by color alone.
- Support dynamic text sizing.
- Maintain readable contrast.
- Provide semantic labels for controls.
- Avoid interactions that require precision while walking.

## Emergency visual hierarchy

Emergency actions must be visually dominant without encouraging accidental activation. Calling professional emergency services remains the primary action. Community assistance is secondary.

## Iconography

Icons use a coherent geometric stroke/fill language. Avoid mixing unrelated icon families. Map, route, wildlife and safety icons should remain recognisable at small sizes.

## Responsive principles

Mobile prioritises one-handed interaction. Tablet and desktop can expose more context without changing the information hierarchy. Web/desktop layouts must preserve the same design language.
