#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PBF_URL="${OSM_SPAIN_PBF_URL:-https://download.geofabrik.de/europe/spain-latest.osm.pbf}"
PBF="$ROOT/data/spain-latest.osm.pbf"

mkdir -p "$ROOT/data" "$ROOT/config"

if [[ ! -s "$PBF" ]]; then
  echo "Downloading Spain OSM extract..."
  curl --fail --location --retry 5 --retry-delay 3 --output "$PBF" "$PBF_URL"
fi

if [[ ! -s "$ROOT/config/valhalla.json" ]]; then
  "$ROOT/build-config.sh"
fi

docker run --rm \
  -v "$ROOT/data:/data/valhalla" \
  -v "$ROOT/config:/config:ro" \
  ghcr.io/valhalla/valhalla:3.9.0 \
  valhalla_build_tiles -c /config/valhalla.json /data/valhalla/spain-latest.osm.pbf

docker run --rm \
  -v "$ROOT/data:/data/valhalla" \
  -v "$ROOT/config:/config:ro" \
  ghcr.io/valhalla/valhalla:3.9.0 \
  valhalla_build_extract -c /config/valhalla.json -v

echo "Spain Valhalla tiles/extract built under $ROOT/data"
