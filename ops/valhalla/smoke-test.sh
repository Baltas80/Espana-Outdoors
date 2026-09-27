#!/usr/bin/env bash
set -euo pipefail

: "${VALHALLA_BASE_URL:?Set VALHALLA_BASE_URL to the real production HTTPS Valhalla endpoint}"

case "${VALHALLA_BASE_URL}" in
  https://*) ;;
  *) echo "ERROR: VALHALLA_BASE_URL must use HTTPS." >&2; exit 1 ;;
esac

BASE="${VALHALLA_BASE_URL%/}"

echo "Checking Valhalla status..."
status_headers="$(curl --fail --silent --show-error --location   --connect-timeout 5 --max-time 15   -D - -o /tmp/valhalla-status.json   "${BASE}/status")"
printf '%s
' "${status_headers}"
grep -qi '^HTTP/.* 200' <<<"${status_headers}"
STATUS_JSON="$(cat /tmp/valhalla-status.json)" python3 - <<'PY'
import json, os
payload=json.loads(os.environ["STATUS_JSON"])
if not isinstance(payload,dict):
    raise SystemExit("Valhalla /status did not return a JSON object.")
print("status_json=valid")
PY

echo "Running routing smoke test..."
curl --fail --silent --show-error --location   --connect-timeout 5 --max-time 30   -H 'content-type: application/json'   --data '{"locations":[{"lat":40.4168,"lon":-3.7038},{"lat":40.4185,"lon":-3.6921}],"costing":"pedestrian","units":"kilometers","shape_format":"geojson","directions_options":{"units":"kilometers","language":"es-ES"}}'   "${BASE}/route" > /tmp/valhalla-route.json
python3 - <<'PY'
import json
from pathlib import Path
payload=json.loads(Path('/tmp/valhalla-route.json').read_text())
trip=payload.get("trip")
legs=trip.get("legs") if isinstance(trip,dict) else None
if not isinstance(trip,dict) or not isinstance(legs,list) or not legs:
    raise SystemExit("Valhalla routing smoke test returned no usable trip/legs.")
print("routing_smoke=valid")
PY

echo "Running elevation smoke test..."
curl --fail --silent --show-error --location   --connect-timeout 5 --max-time 30   -H 'content-type: application/json'   --data '{"range":true,"shape":[{"lat":40.4168,"lon":-3.7038},{"lat":40.4185,"lon":-3.6921}]}'   "${BASE}/height" > /tmp/valhalla-height.json
python3 - <<'PY'
import json
from pathlib import Path
payload=json.loads(Path('/tmp/valhalla-height.json').read_text())
heights=payload.get("range_height")
if not isinstance(heights,list) or not heights:
    raise SystemExit("Valhalla elevation smoke test returned no range_height data.")
print("elevation_smoke=valid")
PY

echo "Valhalla production smoke gate: PASS"
