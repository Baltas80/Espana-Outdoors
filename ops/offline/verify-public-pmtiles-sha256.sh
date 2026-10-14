#!/usr/bin/env bash
set -euo pipefail
if [[ "$#" -lt 1 || "$#" -gt 2 ]]; then
  echo "Usage: $0 CATALOG_HTTPS_URL [MAP_ID]" >&2
  exit 2
fi
catalog_url="$1"
map_id="${2:-spain}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
catalog_file="$tmp_dir/catalog.json"
map_file="$tmp_dir/map.pmtiles"
case "$catalog_url" in https://*) ;; *) echo "ERROR: catalog URL must use HTTPS." >&2; exit 1 ;; esac
curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --connect-timeout 10 --max-time 60 --output "$catalog_file" "$catalog_url"
metadata="$(python3 - "$catalog_file" "$map_id" <<'PY'
import json, re, sys
from urllib.parse import urlparse
path, map_id = sys.argv[1:]
with open(path, encoding="utf-8") as f: data = json.load(f)
if not isinstance(data, list): raise SystemExit("Catalog must be a JSON array.")
entry = next((x for x in data if isinstance(x, dict) and x.get("id") == map_id), None)
if entry is None: raise SystemExit(f"Catalog entry not found: {map_id}")
url = entry.get("downloadUrl")
p = urlparse(url or "")
if p.scheme != "https" or not p.netloc or p.username or p.password: raise SystemExit("downloadUrl must be a valid HTTPS URL.")
size = entry.get("sizeBytes")
if isinstance(size, bool) or not isinstance(size, int) or size <= 0: raise SystemExit("sizeBytes must be a positive integer.")
sha = str(entry.get("sha256", "")).lower()
if not re.fullmatch(r"[0-9a-f]{64}", sha): raise SystemExit("sha256 must be a 64-character SHA-256 hex digest.")
print(url); print(size); print(sha)
PY
)" || exit 1
map_url="$(printf '%s\n' "$metadata" | sed -n '1p')"
expected_size="$(printf '%s\n' "$metadata" | sed -n '2p')"
expected_sha="$(printf '%s\n' "$metadata" | sed -n '3p')"
echo "Downloading the complete PMTiles object to verify its SHA-256."
curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --retry 3 --retry-all-errors --connect-timeout 10 --output "$map_file" "$map_url"
actual_size="$(wc -c < "$map_file" | tr -d '[:space:]')"
if [[ "$actual_size" != "$expected_size" ]]; then echo "ERROR: size mismatch: catalog=$expected_size downloaded=$actual_size" >&2; exit 1; fi
actual_sha="$(sha256sum "$map_file" | awk '{print tolower($1)}')"
if [[ "$actual_sha" != "$expected_sha" ]]; then echo "ERROR: SHA-256 mismatch: catalog=$expected_sha downloaded=$actual_sha" >&2; exit 1; fi
printf 'public_pmtiles_integrity=PASS\nmap_id=%s\nsize_bytes=%s\nsha256=%s\n' "$map_id" "$actual_size" "$actual_sha"
