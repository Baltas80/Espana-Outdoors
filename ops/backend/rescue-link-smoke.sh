#!/usr/bin/env bash
set -euo pipefail

: "${RESCUE_LINK_BASE_URL:?Set RESCUE_LINK_BASE_URL to the real production HTTPS Rescue Link endpoint}"
case "${RESCUE_LINK_BASE_URL}" in
  https://*) ;;
  *) echo "ERROR: RESCUE_LINK_BASE_URL must use HTTPS." >&2; exit 1 ;;
esac

BASE="${RESCUE_LINK_BASE_URL%/}"
headers="$(curl --fail --silent --show-error --location   --connect-timeout 5 --max-time 15   -D - -o /tmp/rescue-link-health.json   "${BASE}/healthz")"
printf '%s
' "${headers}"
grep -qi '^HTTP/.* 200' <<<"${headers}"
python3 - <<'PY'
import json
from pathlib import Path
payload=json.loads(Path('/tmp/rescue-link-health.json').read_text())
if payload.get("status") != "ok":
    raise SystemExit("Rescue Link health is not ok.")
print("rescue_link_health=valid")
PY
echo "Rescue Link production smoke gate: PASS"
