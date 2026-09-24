#!/usr/bin/env bash
set -euo pipefail

: "${MAP_PMTILES_URL:?set MAP_PMTILES_URL to the real production HTTPS object URL}"

echo "Checking HTTPS headers..."
headers="$(curl --fail --silent --show-error --location --head "$MAP_PMTILES_URL")"
printf '%s\n' "$headers"

echo "$headers" | grep -qi '^HTTP/.* 200' || {
  echo "ERROR: production PMTiles URL did not return HTTP 200 to HEAD" >&2
  exit 1
}

echo "Checking byte-range support..."
range_headers="$(curl --fail --silent --show-error --location \
  -H 'Range: bytes=0-1023' \
  -D - -o /dev/null "$MAP_PMTILES_URL")"
printf '%s\n' "$range_headers"

echo "$range_headers" | grep -qi '^HTTP/.* 206' || {
  echo "ERROR: server/CDN did not return HTTP 206 for a byte range request" >&2
  exit 1
}

echo "$range_headers" | grep -qi '^Content-Range:' || {
  echo "ERROR: Content-Range header missing" >&2
  exit 1
}

echo "$range_headers" | grep -qi '^Accept-Ranges: bytes' || {
  echo "WARNING: Accept-Ranges header is not advertised; inspect the CDN before release."
}

echo "PMTiles HTTP range gate: PASS"
