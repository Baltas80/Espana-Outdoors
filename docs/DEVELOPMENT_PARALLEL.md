# España Outdoor — Parallel Development Protocol

This repository is developed as a coordinated multi-track product.

## Active tracks

- Product and UX: distinctive outdoor experience, responsive design, accessibility.
- Mapping/GIS: provider abstraction, route geometry, offline map readiness and GPX.
- Safety: hazards, official alerts, emergency preparation and graceful degradation.
- SOS/Rescue Link: emergency escalation, trusted contacts, temporary location sharing and abuse prevention.
- Pets/wildlife: route suitability, encounter guidance and conservation safeguards.
- Data: official-source adapters, provenance, freshness and licensing.
- Platform: Android, iOS/iPadOS, Web, Windows, macOS and Linux.
- Quality: unit/widget/integration tests, static analysis and CI/CD.
- Security/privacy: least privilege, secure storage, threat modelling and data minimisation.
- Documentation: decisions, operational procedures and production readiness.

## Working rules

1. Independent tracks may advance concurrently.
2. Shared contracts and domain models must remain stable and documented.
3. Do not duplicate provider logic inside UI features.
4. Do not block unrelated work on a missing external credential.
5. Never fabricate external data or successful validation.
6. Critical safety behaviour must fail safely when offline or when a provider is unavailable.
7. Changes must preserve backward compatibility where practical.
8. Every completed capability should include appropriate tests and documentation.

## Definition of done

A feature is not considered production-ready until its normal, loading, error, offline and permission-denied states are considered, relevant tests exist, privacy implications are reviewed, and external dependencies have documented licensing/availability assumptions.
