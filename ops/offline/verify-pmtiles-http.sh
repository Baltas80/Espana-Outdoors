#!/usr/bin/env bash
set -euo pipefail

: "${MAP_PMTILES_URL:?set MAP_PMTILES_URL to the real production HTTPS object URL}"

case "$MAP_PMTILES_URL" in
  https://*) ;;
  *) echo "ERROR: MAP_PMTILES_URL must use HTTPS." >&2; exit 1 ;;
esac

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

echo "Checking HTTPS HEAD response..."
if ! head_status="$(curl --silent --show-error --location --proto-redir '=https' \
  --connect-timeout 5 --max-time 20 --head \
  --dump-header "$tmp_dir/head.headers" --output /dev/null \
  --write-out '%{http_code}' "$MAP_PMTILES_URL")"; then
  echo "ERROR: could not complete PMTiles HEAD request." >&2
  exit 1
fi
if [[ "$head_status" != "200" ]]; then
  echo "ERROR: production PMTiles URL returned HTTP $head_status to HEAD; expected 200." >&2
  exit 1
fi

head_size="$(python3 - "$tmp_dir/head.headers" <<'PY'
import re
import sys

def final_headers(path):
    headers = None
    with open(path, encoding="iso-8859-1") as source:
        for raw in source:
            line = raw.rstrip("\r\n")
            if line.startswith("HTTP/"):
                headers = {"__status__": line.split()[1] if len(line.split()) > 1 else ""}
            elif headers is not None and ":" in line:
                name, value = line.split(":", 1)
                headers[name.strip().lower()] = value.strip()
    return headers or {}

headers = final_headers(sys.argv[1])
length = headers.get("content-length", "")
if not re.fullmatch(r"[0-9]+", length) or int(length) <= 0:
    raise SystemExit("ERROR: HEAD must provide a positive Content-Length for the PMTiles object.")
print(length)
PY
)" || exit 1
echo "HEAD verified: HTTP 200, Content-Length=$head_size bytes"

echo "Checking byte-range support (strict 2 KiB response cap)..."
# Pipe through head rather than writing curl's entire response to disk. If a
# server ignores Range or returns an unbounded/chunked body, head closes the
# pipe after 2 KiB and curl fails instead of downloading the whole map.
set +e
curl --silent --show-error --location --proto-redir '=https' \
  --connect-timeout 5 --max-time 30 \
  --range 0-1023 --dump-header "$tmp_dir/range.headers" \
  "$MAP_PMTILES_URL" | head -c 2049 > "$tmp_dir/range.body"
pipeline_status=("${PIPESTATUS[@]}")
set -e
curl_status="${pipeline_status[0]:-1}"
if [[ "$curl_status" != "0" ]]; then
  echo "ERROR: range request failed or exceeded the 2 KiB response cap; refusing an unbounded map download." >&2
  exit 1
fi

range_status="$(python3 - "$tmp_dir/range.headers" <<'PY'
import sys

status = ""
with open(sys.argv[1], encoding="iso-8859-1") as source:
    for raw in source:
        line = raw.rstrip("\r\n")
        if line.startswith("HTTP/"):
            parts = line.split()
            status = parts[1] if len(parts) > 1 else ""
if not status:
    raise SystemExit("ERROR: range response did not include an HTTP status line.")
print(status)
PY
)" || exit 1

if [[ "$range_status" != "206" ]]; then
  echo "ERROR: server/CDN returned HTTP $range_status for Range bytes=0-1023; expected 206." >&2
  exit 1
fi

python3 - "$tmp_dir/range.headers" "$tmp_dir/range.body" "$head_size" <<'PY'
import os
import re
import sys

def final_headers(path):
    headers = None
    with open(path, encoding="iso-8859-1") as source:
        for raw in source:
            line = raw.rstrip("\r\n")
            if line.startswith("HTTP/"):
                headers = {"__status__": line.split()[1] if len(line.split()) > 1 else ""}
            elif headers is not None and ":" in line:
                name, value = line.split(":", 1)
                headers[name.strip().lower()] = value.strip()
    return headers or {}

headers = final_headers(sys.argv[1])
expected_total = int(sys.argv[3])
value = headers.get("content-range", "")
match = re.fullmatch(r"bytes\s+(\d+)-(\d+)/(\d+)", value, flags=re.IGNORECASE)
if not match:
    raise SystemExit("ERROR: response must contain a valid Content-Range: bytes start-end/total.")
start, end, total = map(int, match.groups())
expected_end = min(1023, expected_total - 1)
if start != 0 or total != expected_total or end != expected_end:
    raise SystemExit(
        f"ERROR: inconsistent Content-Range {value!r}; expected bytes 0-{expected_end}/{expected_total}."
    )
body_size = os.path.getsize(sys.argv[2])
expected_size = end - start + 1
if body_size != expected_size:
    raise SystemExit(
        f"ERROR: range body is {body_size} bytes; expected exactly {expected_size}."
    )
content_length = headers.get("content-length")
if content_length is not None and content_length.isdigit() and int(content_length) != body_size:
    raise SystemExit("ERROR: Content-Length does not match the downloaded range body.")
print(f"Range verified: HTTP 206, {value}, body={body_size} bytes")
PY

if ! grep -qi '^Accept-Ranges: bytes' "$tmp_dir/head.headers"; then
  echo "WARNING: HEAD does not advertise Accept-Ranges: bytes; Range was still verified directly."
fi

echo "PMTiles HTTP range gate: PASS"
