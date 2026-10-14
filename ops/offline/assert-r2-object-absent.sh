#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 3 ]]; then
  echo "Usage: $0 R2_BUCKET OBJECT_KEY R2_ENDPOINT_URL" >&2
  exit 2
fi

bucket="$1"
key="$2"
endpoint="$3"
error_file="$(mktemp)"
trap 'rm -f "$error_file"' EXIT

# First prove the bucket exists and that these credentials can access it.
# This prevents a missing bucket/invalid endpoint from being misread as a
# missing object and accidentally authorizing an upload to the wrong target.
if ! aws s3api head-bucket \
  --bucket "$bucket" \
  --endpoint-url "$endpoint" >/dev/null 2>"$error_file"; then
  cat "$error_file" >&2
  echo "ERROR: could not verify the R2 bucket; refusing to publish an immutable object." >&2
  exit 1
fi

if aws s3api head-object \
  --bucket "$bucket" \
  --key "$key" \
  --endpoint-url "$endpoint" >/dev/null 2>"$error_file"; then
  echo "ERROR: immutable R2 object already exists at s3://$bucket/$key; refusing to overwrite it." >&2
  exit 1
fi

# Authorization, transport, and unknown failures must not be treated as
# evidence that the key is absent. Only a known missing-object response passes.
if grep -Eqi 'NoSuchBucket|AccessDenied|InvalidAccessKeyId|SignatureDoesNotMatch|Could not connect|Could not resolve|timed out|EndpointConnectionError|Forbidden' "$error_file"; then
  cat "$error_file" >&2
  echo "ERROR: could not prove the immutable R2 object is absent; refusing to continue." >&2
  exit 1
fi

if grep -Eqi '\(404\)|NoSuchKey|Not Found' "$error_file"; then
  echo "Confirmed that the immutable R2 object key is absent: s3://$bucket/$key"
  exit 0
fi

cat "$error_file" >&2
echo "ERROR: unrecognized HeadObject failure; refusing to upload or overwrite." >&2
exit 1
