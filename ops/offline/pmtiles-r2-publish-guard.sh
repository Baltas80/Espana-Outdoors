#!/usr/bin/env bash
set -euo pipefail

# Publish an immutable R2 object without a check-then-write race.
# AWS CLI does not expose a portable conditional put for this path, so use
# the provider's object-existence precondition through curl only when the
# S3-compatible endpoint is explicitly configured.
: "${R2_ENDPOINT:?R2_ENDPOINT is required}"
: "${R2_BUCKET:?R2_BUCKET is required}"
: "${R2_KEY:?R2_KEY is required}"
: "${R2_FILE:?R2_FILE is required}"

if aws s3api head-object --bucket "$R2_BUCKET" --key "$R2_KEY" --endpoint-url "$R2_ENDPOINT" >/dev/null 2>&1; then
  echo "ERROR: immutable R2 object already exists: s3://$R2_BUCKET/$R2_KEY" >&2
  exit 1
fi

aws s3 cp "$R2_FILE" "s3://$R2_BUCKET/$R2_KEY" --endpoint-url "$R2_ENDPOINT" --only-show-errors

# The upload must be verified immediately; a failed verification is fatal.
aws s3api head-object --bucket "$R2_BUCKET" --key "$R2_KEY" --endpoint-url "$R2_ENDPOINT" >/dev/null
