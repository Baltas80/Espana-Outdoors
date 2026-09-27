#!/usr/bin/env bash
set -euo pipefail

: "${SOURCE_GATEWAY_BASE_URL:?Set SOURCE_GATEWAY_BASE_URL to the real production HTTPS Source Gateway endpoint}"
case "${SOURCE_GATEWAY_BASE_URL}" in
  https://*) ;;
  *) echo "ERROR: SOURCE_GATEWAY_BASE_URL must use HTTPS." >&2; exit 1 ;;
esac

BASE="${SOURCE_GATEWAY_BASE_URL%/}"
headers="$(curl --fail --silent --show-error --location   --connect-timeout 5 --max-time 15   -D - -o /tmp/source-gateway-health.json   "${BASE}/healthz")"
printf '%s
' "${headers}"
grep -qi '^HTTP/.* 200' <<<"${headers}"
python3 - <<'PY'
import json
from pathlib import Path
payload=json.loads(Path('/tmp/source-gateway-health.json').read_text())
if payload.get("status") != "ok":
    raise SystemExit("Source Gateway health is not ok.")
print("source_gateway_health=valid")
PY
echo "Source Gateway production smoke gate: PASS"
