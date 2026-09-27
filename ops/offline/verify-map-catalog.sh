#!/usr/bin/env bash
set -euo pipefail

: "${OFFLINE_CATALOG_URL:?Set OFFLINE_CATALOG_URL to the real production catalog URL}"

case "${OFFLINE_CATALOG_URL}" in
  https://*) ;;
  *) echo "ERROR: OFFLINE_CATALOG_URL must use HTTPS." >&2; exit 1 ;;
esac

curl --fail --silent --show-error --location   --connect-timeout 5 --max-time 15   --output /tmp/offline-catalog.json   "${OFFLINE_CATALOG_URL}"

OFFLINE_CATALOG_URL="${OFFLINE_CATALOG_URL}" python3 - <<'PY'
import json, os, urllib.parse, urllib.request

catalog_url = os.environ["OFFLINE_CATALOG_URL"]
payload = json.load(open("/tmp/offline-catalog.json", encoding="utf-8"))
if not isinstance(payload, list):
    raise SystemExit("Offline catalog must be a JSON array.")

spain = next((x for x in payload if isinstance(x, dict) and x.get("id") == "spain"), None)
if spain is None:
    raise SystemExit("Offline catalog does not contain the spain entry.")

for key in ("providerId", "licenseUrl", "attribution", "downloadUrl", "sizeBytes", "updatedAt", "sha256"):
    if key not in spain:
        raise SystemExit(f"Catalog spain entry missing {key}.")

if spain["providerId"] != "approved-pmtiles-catalog":
    raise SystemExit("Catalog spain providerId is not approved-pmtiles-catalog.")

for key in ("licenseUrl", "downloadUrl"):
    value = spain[key]
    parsed = urllib.parse.urlparse(value)
    if parsed.scheme != "https" or not parsed.netloc:
        raise SystemExit(f"{key} must be a complete HTTPS URL.")

sha = str(spain["sha256"]).lower()
if len(sha) != 64 or any(c not in "0123456789abcdef" for c in sha):
    raise SystemExit("Catalog spain sha256 is not a valid SHA-256 hex digest.")

size = spain["sizeBytes"]
if not isinstance(size, int) or size <= 0:
    raise SystemExit("Catalog spain sizeBytes must be a positive integer.")

download = spain["downloadUrl"]
request = urllib.request.Request(download, method="HEAD")
with urllib.request.urlopen(request, timeout=15) as response:
    if response.status != 200:
        raise SystemExit(f"PMTiles HEAD returned HTTP {response.status}.")
    remote = response.headers.get("Content-Length")
    if remote is not None and int(remote) != size:
        raise SystemExit(
            f"Catalog sizeBytes={size} does not match remote Content-Length={remote}."
        )

print("catalog_entry=valid")
print("catalog_spain=valid")
print("pmtiles_head=valid")
PY

echo "Offline map catalog smoke gate: PASS"
