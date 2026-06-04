#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
ARTIFACT_BUCKET="${ARTIFACT_BUCKET:-sethcharleston-prod-lambda-artifacts-305372771047-us-east-1}"
ARTIFACT_PREFIX="${ARTIFACT_PREFIX:-production-lambda-import/$(date -u +%Y%m%dT%H%M%SZ)}"

if ! aws s3api head-bucket --bucket "$ARTIFACT_BUCKET" >/dev/null 2>&1; then
  aws s3api create-bucket --bucket "$ARTIFACT_BUCKET" --region "$AWS_REGION" >/dev/null
  aws s3api put-bucket-versioning \
    --bucket "$ARTIFACT_BUCKET" \
    --versioning-configuration Status=Enabled >/dev/null
  aws s3api put-public-access-block \
    --bucket "$ARTIFACT_BUCKET" \
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true >/dev/null
fi

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

for fn in \
  seth_charleston_get_events \
  seth_charleston_post_events \
  seth_charleston_delete_events \
  seth_charleston_get_songs \
  seth_charleston_post_song \
  seth_charleston_delete_songs \
  seth_charleston_get_text \
  seth_charleston_post_text \
  seth_charleston_invalidate_cdn
do
  url="$(aws lambda get-function --function-name "$fn" --region "$AWS_REGION" --query 'Code.Location' --output text)"
  curl -fsSL "$url" -o "${work_dir}/${fn}.zip"
  aws s3 cp "${work_dir}/${fn}.zip" "s3://${ARTIFACT_BUCKET}/${ARTIFACT_PREFIX}/${fn}.zip" --only-show-errors
  echo "${fn}=s3://${ARTIFACT_BUCKET}/${ARTIFACT_PREFIX}/${fn}.zip"
done
