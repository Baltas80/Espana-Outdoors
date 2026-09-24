#!/usr/bin/env bash
set -euo pipefail

# Controlled production map build.
# Requirements on the builder host:
#   - Docker
#   - sha256sum
#   - curl
#
# Planetiler is used for the OSM PBF -> PMTiles conversion. The image tag is
# intentionally pinned through PLANETILER_IMAGE; do not use :latest.
#
# Required environment:
#   PLANETILER_IMAGE=ghcr.io/onthegomap/planetiler:<PINNED_TAG_OR_DIGEST>
# Optional:
#   DATA_DIR=/srv/espana-outdoor/maps
#   OSM_URL=https://download.geofabrik.de/europe/spain-latest.osm.pbf
#   OUTPUT=/srv/espana-outdoor/maps/spain.pmtiles

: "${PLANETILER_IMAGE:?set PLANETILER_IMAGE to a pinned Planetiler image tag or digest}"
DATA_DIR="${DATA_DIR:-$PWD/data}"
OSM_URL="${OSM_URL:-https://download.geofabrik.de/europe/spain-latest.osm.pbf}"
OUTPUT="${OUTPUT:-$DATA_DIR/spain.pmtiles}"

mkdir -p "$DATA_DIR"
PBF="$DATA_DIR/spain.osm.pbf"
mkdir -p "$(dirname "$OUTPUT")"

echo "Downloading OSM extract: $OSM_URL"
curl --fail --location --retry 5 --retry-all-errors --output "$PBF" "$OSM_URL"

echo "Building PMTiles with pinned Planetiler: $PLANETILER_IMAGE"
docker run --rm   -e JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:--Xmx2g}"   -v "$DATA_DIR:/data"   "$PLANETILER_IMAGE"   --osm-path=/data/spain.osm.pbf   --output="/data/$(basename "$OUTPUT")"   --force

test -s "$OUTPUT"

sha256sum "$OUTPUT" > "$OUTPUT.sha256"
wc -c "$OUTPUT" | tee "$OUTPUT.size"

echo
echo "Built:"
echo "  PMTiles: $OUTPUT"
echo "  SHA-256: $(cut -d' ' -f1 "$OUTPUT.sha256")"
