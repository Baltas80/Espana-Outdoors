#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${VALHALLA_BASE_URL:-http://127.0.0.1:8002}"
BASE_URL="${BASE_URL%/}"

status="$(curl --fail --silent --show-error "${BASE_URL}/status")"
STATUS_JSON="$status" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["STATUS_JSON"])
if not isinstance(payload, dict):
    raise SystemExit("Valhalla /status did not return a JSON object.")
PY

response="$(curl --fail --silent --show-error   --request POST "${BASE_URL}/route"   --header 'content-type: application/json'   --data '{
    "locations": [
      {"lat": 40.4168, "lon": -3.7038},
      {"lat": 40.4184, "lon": -3.7049}
    ],
    "costing": "pedestrian",
    "units": "kilometers",
    "shape_format": "geojson",
    "directions_options": {"units": "kilometers", "language": "es-ES"}
  }')"

RESPONSE_JSON="$response" python3 - <<'PY'
import json
import os

payload = json.loads(os.environ["RESPONSE_JSON"])
trip = payload.get("trip")
if not isinstance(trip, dict):
    raise SystemExit("Valhalla smoke route did not return trip data.")
legs = trip.get("legs")
if not isinstance(legs, list) or not legs:
    raise SystemExit("Valhalla smoke route returned no legs.")
print("Valhalla smoke test: OK")
PY
