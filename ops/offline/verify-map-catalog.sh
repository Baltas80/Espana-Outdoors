#!/usr/bin/env bash
set -euo pipefail

: "${OFFLINE_CATALOG_URL:?Set OFFLINE_CATALOG_URL to the real production catalog URL}"

case "${OFFLINE_CATALOG_URL}" in
  https://*) ;;
  *) echo "ERROR: OFFLINE_CATALOG_URL must use HTTPS." >&2; exit 1 ;;
esac

tmp_catalog="$(mktemp)"
trap 'rm -f "$tmp_catalog"' EXIT

curl --fail --silent --show-error --location --proto-redir '=https' \
  --connect-timeout 5 --max-time 15 \
  --output "$tmp_catalog" "${OFFLINE_CATALOG_URL}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
OFFLINE_CATALOG_URL="${OFFLINE_CATALOG_URL}" \
MAP_PMTILES_URL="${MAP_PMTILES_URL:-}" \
  python3 "${SCRIPT_DIR}/validate_map_catalog.py" --catalog-file "$tmp_catalog"

echo "Offline map catalog smoke gate: PASS"
