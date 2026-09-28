#!/usr/bin/env bash
set -euo pipefail

# Publish an already-built Spain PMTiles archive to Cloudflare R2.
# This script intentionally does NOT rebuild the map.
#
# Required environment:
#   R2_ACCOUNT_ID
#   R2_ACCESS_KEY_ID
#   R2_SECRET_ACCESS_KEY
#   R2_BUCKET
#   VERSION=YYYY-MM-DD
#   MAPS_PUBLIC_BASE_URL=https://...
#
# Optional:
#   PMTILES_FILE=/path/to/spain.pmtiles

PMTILES_FILE="${PMTILES_FILE:-$PWD/data/spain.pmtiles}"
VERSION="${VERSION:-}"
: "${R2_ACCOUNT_ID:?Set R2_ACCOUNT_ID}"
: "${R2_ACCESS_KEY_ID:?Set R2_ACCESS_KEY_ID}"
: "${R2_SECRET_ACCESS_KEY:?Set R2_SECRET_ACCESS_KEY}"
: "${R2_BUCKET:?Set R2_BUCKET}"
: "${VERSION:?Set VERSION as YYYY-MM-DD}"
: "${MAPS_PUBLIC_BASE_URL:?Set MAPS_PUBLIC_BASE_URL to the public HTTPS base URL}"

if [[ ! "${VERSION}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
  echo "ERROR: VERSION must use YYYY-MM-DD." >&2
  exit 1
fi

test -s "${PMTILES_FILE}" || {
  echo "ERROR: PMTiles file not found or empty: ${PMTILES_FILE}" >&2
  exit 1
}

case "${MAPS_PUBLIC_BASE_URL}" in
  https://*) ;;
  *) echo "ERROR: MAPS_PUBLIC_BASE_URL must be HTTPS." >&2; exit 1 ;;
esac

export AWS_ACCESS_KEY_ID="${R2_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION=auto

ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
PREFIX="basemap/spain/${VERSION}"
REMOTE="${PREFIX}/spain.pmtiles"
CHECKSUM_FILE="${PMTILES_FILE}.sha256"
URL="${MAPS_PUBLIC_BASE_URL%/}/${REMOTE}"

echo "== España Outdoor / PMTiles publish =="
echo "File:     ${PMTILES_FILE}"
echo "Version:  ${VERSION}"
echo "Bucket:   ${R2_BUCKET}"
echo "Remote:   ${REMOTE}"

KEY_LEN="${#AWS_ACCESS_KEY_ID}"
if [[ "${KEY_LEN}" -ne 32 ]]; then
  echo "ERROR: R2_ACCESS_KEY_ID has ${KEY_LEN} characters. Cloudflare R2 Access Key IDs are 32 characters." >&2
  echo "Do not put the API-token value in AWS_ACCESS_KEY_ID." >&2
  exit 1
fi

echo "Checking R2 bucket access..."
aws s3api head-bucket   --bucket "${R2_BUCKET}"   --endpoint-url "${ENDPOINT}" >/dev/null

echo "Calculating SHA-256..."
SHA256="$(sha256sum "${PMTILES_FILE}" | cut -d' ' -f1)"
SIZE="$(stat -c '%s' "${PMTILES_FILE}")"
printf '%s  %s\n' "${SHA256}" "${PMTILES_FILE}" | tee "${CHECKSUM_FILE}"

echo "Uploading PMTiles..."
aws s3 cp "${PMTILES_FILE}" "s3://${R2_BUCKET}/${REMOTE}"   --endpoint-url "${ENDPOINT}"   --content-type application/octet-stream   --cache-control "public, max-age=31536000, immutable"   --metadata "sha256=${SHA256}"

echo "Uploading checksum..."
aws s3 cp "${CHECKSUM_FILE}" "s3://${R2_BUCKET}/${REMOTE}.sha256"   --endpoint-url "${ENDPOINT}"   --content-type text/plain   --cache-control "public, max-age=31536000, immutable"

echo "Verifying remote object..."
REMOTE_SIZE="$(aws s3api head-object   --bucket "${R2_BUCKET}"   --key "${REMOTE}"   --endpoint-url "${ENDPOINT}"   --query ContentLength   --output text)"

REMOTE_SHA="$(aws s3api head-object   --bucket "${R2_BUCKET}"   --key "${REMOTE}"   --endpoint-url "${ENDPOINT}"   --query 'Metadata.sha256'   --output text)"

test "${REMOTE_SIZE}" = "${SIZE}"
test "${REMOTE_SHA}" = "${SHA256}"

echo "Remote object verified:"
echo "  size   = ${REMOTE_SIZE}"
echo "  sha256 = ${REMOTE_SHA}"

if command -v curl >/dev/null 2>&1; then
  echo "Checking public HTTPS byte ranges..."
  headers="$(curl --fail --silent --show-error --location --head "${URL}")"
  echo "${headers}" | grep -qi '^HTTP/.* 200' || {
    echo "ERROR: public URL did not return HTTP 200." >&2
    exit 1
  }

  range_headers="$(curl --fail --silent --show-error --location     -H 'Range: bytes=0-1023'     -D - -o /dev/null "${URL}")"

  echo "${range_headers}" | grep -qi '^HTTP/.* 206' || {
    echo "ERROR: public URL did not return HTTP 206 for byte range." >&2
    exit 1
  }

  echo "${range_headers}" | grep -qi '^Content-Range:' || {
    echo "ERROR: Content-Range header missing." >&2
    exit 1
  }
fi

echo
echo "PASS: PMTiles published and verified."
echo "${URL}"
