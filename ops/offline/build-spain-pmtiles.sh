#!/usr/bin/env bash
set -euo pipefail

# Controlled production map build.
# Uses mature, pinned upstream tooling. No public OSM tile server is used.
#
# Requirements:
#   - Java 21+
#   - curl
#   - sha256sum
#
# Inputs:
#   DATA_DIR=/srv/espana-outdoor/maps
#   OSM_URL=<immutable/versioned Geofabrik PBF URL>
#   OUTPUT=<path to PMTiles output>

DATA_DIR="${DATA_DIR:-$PWD/data}"
OSM_URL="${OSM_URL:-}"
OUTPUT="${OUTPUT:-$DATA_DIR/spain.pmtiles}"

PLANETILER_VERSION="0.10.2"
PLANETILER_SHA256="f310bd0413e2e4512b27f4046d418664e8e1d3bf31603c2a70e23de06c167e4d"
PLANETILER_URL="https://github.com/onthegomap/planetiler/releases/download/v${PLANETILER_VERSION}/planetiler.jar"

: "${OSM_URL:?Set OSM_URL explicitly to an immutable/versioned Geofabrik Spain OSM PBF URL}"

case "$OSM_URL" in
  https://download.geofabrik.de/*.osm.pbf) ;;
  *)
    echo "ERROR: OSM_URL must be an HTTPS Geofabrik OSM PBF URL." >&2
    exit 1
    ;;
esac

mkdir -p "$DATA_DIR"
PBF="$DATA_DIR/spain.osm.pbf"
JAR="$DATA_DIR/planetiler.jar"
mkdir -p "$(dirname "$OUTPUT")"

if [[ -s "$PBF" ]]; then
  echo "Using existing OSM extract: $PBF"
else
  echo "Downloading OSM extract: $OSM_URL"
  curl --fail --location --retry 5 --retry-all-errors --output "$PBF" "$OSM_URL"
fi
sha256sum "$PBF" | tee "$PBF.sha256"

echo "Downloading pinned Planetiler v$PLANETILER_VERSION"
curl --fail --location --retry 5 --retry-all-errors --output "$JAR" "$PLANETILER_URL"
echo "$PLANETILER_SHA256  $JAR" | sha256sum -c -

echo "Building PMTiles"
java -Xmx4g -jar "$JAR" \
  --osm-path="$PBF" \
  --output="$OUTPUT" \
  --force

test -s "$OUTPUT"

sha256sum "$OUTPUT" | tee "$OUTPUT.sha256"
wc -c "$OUTPUT" | tee "$OUTPUT.size"
cat > "$OUTPUT.build-manifest.txt" <<EOF
planetiler_version=$PLANETILER_VERSION
planetiler_sha256=$PLANETILER_SHA256
osm_url=$OSM_URL
osm_pbf_sha256=$(cut -d" " -f1 "$PBF.sha256")
pmtiles_sha256=$(cut -d" " -f1 "$OUTPUT.sha256")
pmtiles_size_bytes=$(cut -d" " -f1 "$OUTPUT.size")
created_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

echo
echo "Built:"
echo "  PMTiles: $OUTPUT"
echo "  SHA-256: $(cut -d' ' -f1 "$OUTPUT.sha256")"
