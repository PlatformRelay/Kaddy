#!/usr/bin/env bash
# REQ-E13-S01-01 — golden image exported as a .gz snapshot to object storage.
#
# LIVE, gated on E1g credits + a real object-storage bucket. This is one of the
# three E13 live smoke scripts; it is NOT wired into the CI/verify gate (the
# green offline gate is tests/smoke/e13-offline.sh). By design it SKIPs (exit 0)
# when creds/tooling are absent so it can never redden CI — the real assertions
# run only at the live build/export cycle (see docs/runbooks/gridscale-marketplace-deploy.md).
#
# Asserts: the exported object exists at the s3:// .gz path suitable for a
# gridscale_marketplace_application.object_storage_path.
set -euo pipefail

: "${MARKETPLACE_ENGINE:=caddy}"
: "${IMAGES_BUCKET:=kaddy-images}"
: "${OBJECT_KEY:=${MARKETPLACE_ENGINE}-golden.gz}"

# --- Gate: need creds (object-storage S3 keys) + the aws/s3 CLI to inspect ----
if [[ -z "${STATE_ACCESS_KEY:-}${AWS_ACCESS_KEY_ID:-}" ]]; then
  echo "SKIP: no object-storage credentials (STATE_ACCESS_KEY/AWS_ACCESS_KEY_ID unset) — live export not run; see the runbook"
  exit 0
fi
if ! command -v aws >/dev/null 2>&1; then
  echo "SKIP: aws CLI not installed — cannot inspect the s3:// bucket for the exported .gz"
  exit 0
fi

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-${STATE_ACCESS_KEY}}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-${STATE_SECRET_KEY:-}}"
S3_ENDPOINT="${S3_ENDPOINT:-https://gos3.io}"
S3_URI="s3://${IMAGES_BUCKET}/${OBJECT_KEY}"

# The path MUST be a .gz starting s3:// (the marketplace-API constraint).
[[ "${S3_URI}" =~ ^s3://.+\.gz$ ]] \
  || { echo "FAIL: object path ${S3_URI} is not an s3:// .gz path" >&2; exit 1; }

# Live assertion: the exported snapshot object exists in the bucket.
if aws --endpoint-url "${S3_ENDPOINT}" s3 ls "${S3_URI}" >/dev/null 2>&1; then
  echo "OK: REQ-E13-S01-01 exported snapshot present at ${S3_URI}"
else
  echo "FAIL: no exported snapshot at ${S3_URI} — run 'task e13:export' (see the runbook)" >&2
  exit 1
fi
