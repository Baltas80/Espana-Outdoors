# España Outdoor — Data Source Registry v0.1

This registry is the contract for every live or static external dataset used by the product. A source is not production-approved until provenance, licence, freshness, availability, attribution and failure behaviour are documented.

| Domain | Candidate source | Role | Status |
|---|---|---|---|
| Base map | OpenStreetMap | Roads, paths, POI and geographic context | MVP/dev only for public tiles; production tile service pending |
| Weather | AEMET OpenData | Forecasts and meteorological observations | Candidate; connector pending |
| National cartography | IGN/CNIG | Official geographic/cartographic layers | Candidate; connector and licence review pending |
| Protected areas / nature | MITECO and official regional sources | Conservation, protected areas and restrictions | Candidate; source-by-source review pending |
| Civil protection | Protección Civil / official regional services | Official alerts and emergency information | Candidate; source-by-source review pending |
| Regional data | Autonomous communities / diputaciones / ayuntamientos | Local restrictions, services and environmental data | Candidate; source-by-source review pending |

## Required provenance fields

Every normalized record must preserve:

- `sourceId`
- `sourceName`
- `sourceUrl`
- `license`
- `attribution`
- `retrievedAt`
- `sourceUpdatedAt` when provided
- `validFrom` / `validUntil` when applicable
- `confidence`
- `transformVersion`
- `originalRecordId` when available

## Official alert rule

An external warning may be displayed as **ALERTA OFICIAL** only when the source itself is an official authority for that warning. España Outdoor recommendations are a separate semantic class: **AVISO DE ESPAÑA OUTDOOR**.

The UI must never merge the two into a single confidence signal.

## AEMET operational note

AEMET OpenData provides a REST API for reusable meteorological data. The connector must keep API credentials outside Git, support expiration/rotation, and surface source freshness. AEMET published a current notice that API keys without an expiration date will cease to be valid from **15 October 2026**.

Source: https://opendata.aemet.es/centrodedescargas/novedades

## OSM operational note

OSM data and OSM public tile service are different things. The public OSM tile service is best-effort and explicitly disallows bulk downloading/offline prefetching. España Outdoor therefore requires a separately licensed/self-hosted tile strategy for offline maps.

Source: https://operations.osmfoundation.org/policies/tiles/

## Data lifecycle

```text
External source
    ↓
Connector
    ↓
Raw/staged record
    ↓
Validation + provenance
    ↓
Normalization
    ↓
Freshness/expiry policy
    ↓
Domain store / tile store
    ↓
API + offline package
    ↓
UI
```

A failed source must not silently produce fresh-looking data. The system should retain the last known record with explicit staleness metadata when product policy permits it.
