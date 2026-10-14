#!/usr/bin/env bash
set -euo pipefail

# Idempotently provision the public R2 bucket endpoint used for PMTiles.
# This script never creates DNS records outside Cloudflare's R2 custom-domain flow,
# never enables the r2.dev endpoint, and never prints API credentials.

: "${CLOUDFLARE_API_TOKEN:?Set CLOUDFLARE_API_TOKEN in the maps-production GitHub Environment}"
: "${R2_ACCOUNT_ID:?Set R2_ACCOUNT_ID in the maps-production GitHub Environment}"
: "${CLOUDFLARE_ZONE_ID:?Set CLOUDFLARE_ZONE_ID as a maps-production environment variable}"
: "${R2_BUCKET:?Set R2_BUCKET as a maps-production environment variable}"
: "${MAPS_PUBLIC_BASE_URL:?Set MAPS_PUBLIC_BASE_URL as a maps-production environment variable}"

API_BASE="https://api.cloudflare.com/client/v4"
LOCATION_HINT="${R2_LOCATION_HINT:-weur}"
WAIT_ATTEMPTS="${R2_DOMAIN_WAIT_ATTEMPTS:-36}"
WAIT_SECONDS="${R2_DOMAIN_WAIT_SECONDS:-10}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ "$R2_ACCOUNT_ID" =~ ^[a-fA-F0-9]{32}$ ]] || fail "R2_ACCOUNT_ID must be a 32-character Cloudflare account ID."
[[ "$CLOUDFLARE_ZONE_ID" =~ ^[a-fA-F0-9]{32}$ ]] || fail "CLOUDFLARE_ZONE_ID must be a 32-character zone ID."
[[ "$R2_BUCKET" =~ ^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$ ]] || fail "R2_BUCKET must be 3-63 lowercase letters, numbers, or interior hyphens."
[[ "$LOCATION_HINT" =~ ^(apac|eeur|enam|weur|wnam|oc)$ ]] || fail "R2_LOCATION_HINT must be apac, eeur, enam, weur, wnam, or oc."
[[ "$WAIT_ATTEMPTS" =~ ^[1-9][0-9]*$ && "$WAIT_SECONDS" =~ ^[1-9][0-9]*$ ]] || fail "Domain wait settings must be positive integers."

DOMAIN="$(MAPS_PUBLIC_BASE_URL="$MAPS_PUBLIC_BASE_URL" python3 - <<'PY'
import os
import sys
from urllib.parse import urlsplit

raw = os.environ["MAPS_PUBLIC_BASE_URL"].strip()
parsed = urlsplit(raw)
if (
    parsed.scheme != "https"
    or not parsed.hostname
    or parsed.username
    or parsed.password
    or parsed.port is not None
    or parsed.path not in ("", "/")
    or parsed.query
    or parsed.fragment
):
    sys.exit("MAPS_PUBLIC_BASE_URL must be an HTTPS origin only, e.g. https://maps.your-domain.es")
host = parsed.hostname.lower().rstrip(".")
if host == "localhost" or "." not in host or any(c not in "abcdefghijklmnopqrstuvwxyz0123456789.-" for c in host):
    sys.exit("MAPS_PUBLIC_BASE_URL must use a real DNS hostname.")
print(host)
PY
)" || fail "Invalid MAPS_PUBLIC_BASE_URL."

api_request() {
  local method="$1"
  local path="$2"
  local payload="${3:-}"
  local output_file="$tmp_dir/response.json"
  local code
  local -a args

  args=(--silent --show-error --connect-timeout 10 --max-time 45
        --output "$output_file" --write-out '%{http_code}'
        --request "$method"
        --header "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}"
        --header 'Content-Type: application/json')
  if [[ -n "$payload" ]]; then args+=(--data "$payload"); fi

  code="$(curl "${args[@]}" "${API_BASE}${path}")" || fail "Cloudflare API request failed at ${path} (network/TLS error)."
  if [[ "$code" != 2?? ]] || ! jq -e '.success == true' "$output_file" >/dev/null 2>&1; then
    printf 'Cloudflare API response (%s %s, HTTP %s):\n' "$method" "$path" "$code" >&2
    jq -c '{success, errors, messages}' "$output_file" >&2 2>/dev/null || cat "$output_file" >&2
    return 1
  fi
  cat "$output_file"
}

printf 'Checking Cloudflare R2 bucket "%s"...\n' "$R2_BUCKET"
bucket_path="/accounts/${R2_ACCOUNT_ID}/r2/buckets/${R2_BUCKET}"
bucket_code="$(curl --silent --show-error --connect-timeout 10 --max-time 45 \
  --output "$tmp_dir/bucket.json" --write-out '%{http_code}' \
  --header "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  "${API_BASE}${bucket_path}")" || fail "Cloudflare API request failed while checking the bucket."
if [[ "$bucket_code" == "200" ]] && jq -e '.success == true and .result.name == env.R2_BUCKET' "$tmp_dir/bucket.json" >/dev/null; then
  printf 'Bucket already exists; leaving its data and settings untouched.\n'
elif [[ "$bucket_code" == "404" ]]; then
  printf 'Creating bucket in location hint "%s"...\n' "$LOCATION_HINT"
  api_request POST "/accounts/${R2_ACCOUNT_ID}/r2/buckets" \
    "$(jq -cn --arg name "$R2_BUCKET" --arg location "$LOCATION_HINT" \
      '{name:$name, locationHint:$location, storageClass:"Standard"}')" >/dev/null \
    || fail "Could not create R2 bucket."
else
  jq -c '{success, errors, messages}' "$tmp_dir/bucket.json" >&2 2>/dev/null || true
  fail "Could not read R2 bucket (HTTP ${bucket_code}); check API token scope and account ID."
fi

domains_path="/accounts/${R2_ACCOUNT_ID}/r2/buckets/${R2_BUCKET}/domains/custom"
printf 'Checking custom domain "%s"...\n' "$DOMAIN"
domain_list="$(api_request GET "$domains_path")" || fail "Could not list custom domains for the R2 bucket."
existing="$(printf '%s' "$domain_list" | jq -c --arg domain "$DOMAIN" \
  '[.result.domains[]? | select(.domain == $domain)] | first // empty')"

if [[ -z "$existing" ]]; then
  printf 'Attaching HTTPS custom domain...\n'
  api_request POST "$domains_path" \
    "$(jq -cn --arg domain "$DOMAIN" --arg zone "$CLOUDFLARE_ZONE_ID" \
      '{domain:$domain, zoneId:$zone, enabled:true, minTLS:"1.2"}')" >/dev/null \
    || fail "Could not attach domain. Verify the domain is a zone in this same Cloudflare account and is not attached to another bucket."
elif [[ "$(printf '%s' "$existing" | jq -r '.zoneId // empty')" != "$CLOUDFLARE_ZONE_ID" ]]; then
  fail "The domain is attached to this bucket with a different zone ID; refusing to mutate it."
elif [[ "$(printf '%s' "$existing" | jq -r '.enabled // false')" != "true" || "$(printf '%s' "$existing" | jq -r '.minTLS // "1.0"')" != "1.2" ]]; then
  printf 'Enabling the existing custom domain with minimum TLS 1.2...\n'
  api_request PUT "${domains_path}/${DOMAIN}" \
    '{"enabled":true,"minTLS":"1.2"}' >/dev/null \
    || fail "Could not update the existing custom-domain settings."
else
  printf 'Custom domain is already attached and enabled.\n'
fi

printf 'Waiting for Cloudflare ownership and TLS certificate status...\n'
for ((attempt=1; attempt<=WAIT_ATTEMPTS; attempt++)); do
  domain_list="$(api_request GET "$domains_path")" || fail "Could not poll custom-domain status."
  status="$(printf '%s' "$domain_list" | jq -c --arg domain "$DOMAIN" \
    '[.result.domains[]? | select(.domain == $domain)] | first // empty')"
  [[ -n "$status" ]] || fail "Cloudflare no longer lists the configured custom domain."
  ownership="$(printf '%s' "$status" | jq -r '.status.ownership // "unknown"')"
  ssl="$(printf '%s' "$status" | jq -r '.status.ssl // "unknown"')"
  printf 'Attempt %s/%s: ownership=%s tls=%s\n' "$attempt" "$WAIT_ATTEMPTS" "$ownership" "$ssl"
  if [[ "$ownership" == "active" && "$ssl" == "active" ]]; then
    break
  fi
  if [[ "$ownership" == "blocked" || "$ownership" == "error" || "$ssl" == "error" || "$ssl" == "deactivated" ]]; then
    fail "Cloudflare reported an unusable custom-domain state; inspect the zone and certificate in the dashboard."
  fi
  if (( attempt < WAIT_ATTEMPTS )); then sleep "$WAIT_SECONDS"; fi
done

[[ "${ownership:-}" == "active" && "${ssl:-}" == "active" ]] || \
  fail "Domain/TLS did not become active before timeout. Re-run after correcting the domain configuration."

printf '\nR2 storage endpoint provisioned:\n'
printf '  bucket: %s\n' "$R2_BUCKET"
printf '  domain: https://%s\n' "$DOMAIN"
printf '  object URL after PMTiles upload: https://%s/spain.pmtiles\n' "$DOMAIN"
printf '  TLS minimum: 1.2\n'
printf '  r2.dev endpoint: not enabled by this script\n'
printf '\nNext gate: upload the reviewed PMTiles artifact and verify HEAD 200 plus Range 206/Content-Range.\n'
