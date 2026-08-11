#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${1:?Usage: publish-static-site.sh SOURCE_DIR BUCKET DISTRIBUTION_ID}"
SITE_BUCKET="${2:?Usage: publish-static-site.sh SOURCE_DIR BUCKET DISTRIBUTION_ID}"
DISTRIBUTION_ID="${3:?Usage: publish-static-site.sh SOURCE_DIR BUCKET DISTRIBUTION_ID}"

aws s3 sync "$SOURCE_DIR/" "s3://$SITE_BUCKET/" \
  --delete \
  --exclude "*.html" \
  --exclude "sitemap.xml" \
  --cache-control "public,max-age=86400" \
  --only-show-errors

aws s3 sync "$SOURCE_DIR/" "s3://$SITE_BUCKET/" \
  --delete \
  --exclude "*" \
  --include "*.html" \
  --cache-control "public,max-age=300,must-revalidate" \
  --content-type "text/html; charset=utf-8" \
  --only-show-errors

aws s3 cp "$SOURCE_DIR/sitemap.xml" "s3://$SITE_BUCKET/sitemap.xml" \
  --cache-control "public,max-age=300,must-revalidate" \
  --content-type "application/xml; charset=utf-8" \
  --only-show-errors

aws cloudfront create-invalidation \
  --distribution-id "$DISTRIBUTION_ID" \
  --paths "/*" \
  --output json

