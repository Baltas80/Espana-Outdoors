# CNIG cartography acquisition playbook

## Purpose

Acquire only the source datasets that España Outdoor can validate, process and legally redistribute. The CNIG catalogue contains products, historical editions, auxiliary files and thousands of individual tiles; the number of search results is not a download plan.

This is an operational checklist, not a claim that a particular set of downloads covers all of Spain.

## Hard stops before starting a bulk download

1. Never use **Add all / Añadir todos** until the selected product, geographic coverage and total size have been reviewed.
2. Read the downloader's **total file count and total estimated size** before starting. Cancel if it exceeds the approved storage budget.
3. Confirm free disk space for the download **and** extraction/processing. Keep a safety margin; compressed archive size is not the final working-space requirement.
4. Record product name, edition/date, format, coverage, licence/terms, expected file count, expected bytes and source URL.
5. Download into an originals directory. Do not overwrite verified originals with converted or processed outputs.
6. Treat XML sidecars and ZIP files as product-specific auxiliaries. Do not discard them blindly; establish their purpose first.
7. Do not merge products with different vintages or resolutions until their coverage and semantics have been checked.

## Evidence from catalogue selection

The CNIG downloader has shown why a national bulk selection must be inspected first:

- A PNOA selection displayed **25,360 files / approximately 6,962,636 MB (~6.96 TB)**.
- An MDT05 selection displayed **38,079 files / approximately 3,704,052 MB (~3.70 TB)**.

These are observed totals for those selections, not universal product sizes. Both exceed a 130 GB planning budget and must not be started as whole-catalogue downloads.

## Recommended acquisition order

### 1. Existing Spain Outdoor basemap artifact

Use the published, versioned PMTiles artifact and its catalogue metadata as the baseline. Verify the complete downloaded file against the published SHA-256 before treating it as trusted. Do not confuse successful HTTP HEAD/Range checks with a full-object digest verification.

### 2. National vector reference data

Review the CNIG/IGN products below one by one. Prefer a single national dataset when the catalogue explicitly offers one and its licence/format are suitable.

- BTN thematic GeoPackages: transport, hydrography, orography, populations, nature/landscape, services/facilities and culture/leisure.
- Nomenclátor Geográfico Básico de España.
- National administrative boundaries (municipal, provincial and autonomous-community levels).
- CartoCiudad or equivalent only where its content adds value beyond existing layers.

Before adding a thematic BTN package, record its exact name, edition, format, size and whether it overlaps with another selected product. Avoid downloading alternate formats of the same dataset without a clear need.

### 3. Elevation

MDT05 is a useful source for terrain profiles, elevation gain and slope analysis, but its full catalogue selection is multi-terabyte. Do not download all tiles by default.

First define a geographic coverage manifest (for example, a set of regions or bounding boxes), select only intersecting tiles, and calculate their aggregate size. Validate coordinate reference system, nodata handling, resolution, source date and tile-edge continuity before generating derivative products.

If whole-Spain 5 m coverage does not fit the approved budget, propose a lower-resolution national dataset plus higher-resolution coverage for priority areas. This is a product/coverage trade-off and must be documented rather than hidden.

### 4. Topographic maps and aerial imagery

- Evaluate MTN25 raster coverage and size before downloading.
- PNOA Máxima Actualidad is optional imagery, not a prerequisite for the first functional offline basemap.
- Never select all PNOA files merely because the product is relevant. Use a coverage manifest and a total-size check first.
- Defer LiDAR and high-resolution surface models until a concrete product requirement justifies their volume.

## Storage budget and directory layout

The initial working budget may be set to 130 GB, but this is a cap for planning, not evidence that full national MDT05, MTN25 or PNOA coverage fits within it. Recalculate after collecting exact product sizes.

Keep sources, verified originals and derived data separate:

```text
maps/
  manifests/
  originals/
    cnig/
      btn/
      elevation/
      topographic/
      nomenclator/
      boundaries/
      imagery/
    espana-outdoor/
  verified/
  derived/
  reports/
```

Do not commit bulk map files, credentials, local absolute paths or generated data to the application repository.

## Required manifest per selected product

Keep one record per product or tile set with:

- product identifier and displayed title;
- issuing authority and source URL;
- edition/retrieval date;
- geographic coverage or tile IDs;
- coordinate reference system and resolution, where applicable;
- format and licence/attribution requirements;
- expected size and actual size;
- SHA-256 for each completed file (or a documented manifest digest);
- verification status and any failures;
- processing command/version for derived outputs.

A file is not verified just because the downloader marks it complete. Compare size and checksum where the source provides one, and open representative files with the intended GIS tooling.

## Release gate

Do not publish a derived offline package until coverage gaps, overlaps, coordinate reference systems, attribution/licence obligations, data freshness and checksums have been reviewed. Safety-relevant information such as access restrictions, closures, hazards and weather requires a freshness policy and must not be treated as static basemap truth.
