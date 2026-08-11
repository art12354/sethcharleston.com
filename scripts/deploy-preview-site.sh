#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AWS_REGION="${AWS_REGION:-us-east-1}"
BRANCH_NAME="${BRANCH_NAME:-$(git branch --show-current 2>/dev/null || true)}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-Z27ZS6MVE7C6ZT}"
ACM_CERTIFICATE_ARN="${ACM_CERTIFICATE_ARN:-arn:aws:acm:us-east-1:305372771047:certificate/2db52ae6-5372-472a-b689-42126941926a}"

slug="$(
  printf '%s' "$BRANCH_NAME" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's#[^a-z0-9]+#-#g; s#^-+##; s#-+$##; s#-{2,}#-#g' \
    | cut -c1-42
)"

if [[ -z "$slug" || "$slug" == "master" || "$slug" == "main" ]]; then
  echo "Branch '$BRANCH_NAME' cannot be deployed as a preview." >&2
  exit 1
fi

stack_name="sethcharleston-preview-${slug}"
domain_name="${slug}.sethcharleston.com"

aws cloudformation deploy \
  --stack-name "$stack_name" \
  --template-file "$ROOT_DIR/infra/cloudformation/preview-static-site.yaml" \
  --region "$AWS_REGION" \
  --parameter-overrides \
    DomainName="$domain_name" \
    HostedZoneId="$HOSTED_ZONE_ID" \
    AcmCertificateArn="$ACM_CERTIFICATE_ARN" \
  --tags Project=sethcharleston Environment=preview Branch="$slug" ManagedBy=cloudformation \
  --no-fail-on-empty-changeset

bucket="$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='SiteBucketName'].OutputValue | [0]" --output text)"
distribution="$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue | [0]" --output text)"

work_dir="$(mktemp -d)"
mkdir -p "$work_dir/site"
cp "$ROOT_DIR"/index.html "$ROOT_DIR"/about.html "$ROOT_DIR"/music.html "$ROOT_DIR"/shows.html "$ROOT_DIR"/sitemap.xml "$work_dir/site/"
cp -R "$ROOT_DIR"/css "$ROOT_DIR"/photos "$ROOT_DIR"/videos "$work_dir/site/"
find "$work_dir/site" -type f -name "*.html" -print0 \
  | xargs -0 sed -i 's#https://api.sethcharleston.com#https://api-staging.sethcharleston.com#g'

"$ROOT_DIR/scripts/publish-static-site.sh" "$work_dir/site" "$bucket" "$distribution"
curl --fail --silent --show-error --retry 5 --retry-delay 10 --head "https://${domain_name}"
echo "Preview deployed to https://${domain_name}"

