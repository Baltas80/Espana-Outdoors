#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$ROOT/data" "$ROOT/config"

docker run --rm \
  -v "$ROOT/data:/data/valhalla" \
  ghcr.io/valhalla/valhalla:3.9.0 \
  valhalla_build_config \
    --mjolnir-tile-dir /data/valhalla/tiles \
    --mjolnir-tile-extract /data/valhalla/tiles.tar \
    --mjolnir-timezone /data/valhalla/timezones.sqlite \
    --mjolnir-admin /data/valhalla/admins.sqlite \
    --mjolnir-concurrency 4 \
  > "$ROOT/config/valhalla.json"

echo "Generated $ROOT/config/valhalla.json"
