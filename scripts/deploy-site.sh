#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

STACK_NAME="${STACK_NAME:-sethcharleston-static-site}"
AWS_REGION="${AWS_REGION:-us-east-1}"
CACHE_CONTROL_HTML="${CACHE_CONTROL_HTML:-public,max-age=300,must-revalidate}"
CACHE_CONTROL_ASSETS="${CACHE_CONTROL_ASSETS:-public,max-age=86400}"

stack_output() {
  local key="$1"
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='${key}'].OutputValue | [0]" \
    --output text
}

SITE_BUCKET="$(stack_output SiteBucketName)"
DISTRIBUTION_ID="$(stack_output CloudFrontDistributionId)"
WEBSITE_URL="$(stack_output WebsiteUrl)"

if [[ -z "$SITE_BUCKET" || "$SITE_BUCKET" == "None" ]]; then
  echo "Could not find SiteBucketName output for stack '$STACK_NAME' in '$AWS_REGION'." >&2
  exit 1
fi

aws s3 sync "$ROOT_DIR/" "s3://$SITE_BUCKET/" \
  --delete \
  --exclude ".git/*" \
  --exclude ".github/*" \
  --exclude "infra/*" \
  --exclude "scripts/*" \
  --exclude "README.md" \
  --exclude "*.html" \
  --exclude "sitemap.xml" \
  --cache-control "$CACHE_CONTROL_ASSETS"

aws s3 sync "$ROOT_DIR/" "s3://$SITE_BUCKET/" \
  --delete \
  --exclude "*" \
  --include "*.html" \
  --cache-control "$CACHE_CONTROL_HTML" \
  --content-type "text/html; charset=utf-8"

aws s3 cp "$ROOT_DIR/sitemap.xml" "s3://$SITE_BUCKET/sitemap.xml" \
  --cache-control "$CACHE_CONTROL_HTML" \
  --content-type "application/xml; charset=utf-8"

if [[ -n "$DISTRIBUTION_ID" && "$DISTRIBUTION_ID" != "None" ]]; then
  aws cloudfront create-invalidation \
    --distribution-id "$DISTRIBUTION_ID" \
    --paths "/*" \
    --query "Invalidation.{Id:Id,Status:Status}" \
    --output table
fi

echo "Deployed to $WEBSITE_URL"
