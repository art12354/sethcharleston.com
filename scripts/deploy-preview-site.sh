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

stack_name="sethcharleston-branch-${slug}-site"
domain_name="${slug}.sethcharleston.com"
editor_domain_name="edit-${slug}.sethcharleston.com"
editor_asset_version="$(git -C "$ROOT_DIR" rev-parse --short HEAD)"

aws cloudformation deploy \
  --stack-name "$stack_name" \
  --template-file "$ROOT_DIR/infra/cloudformation/preview-static-site.yaml" \
  --region "$AWS_REGION" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    DomainName="$domain_name" \
    EditorDomainName="$editor_domain_name" \
    PreviewId="$slug" \
    HostedZoneId="$HOSTED_ZONE_ID" \
    AcmCertificateArn="$ACM_CERTIFICATE_ARN" \
  --tags Project=sethcharleston Environment=preview Branch="$slug" ManagedBy=cloudformation \
  --no-fail-on-empty-changeset

bucket="$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='SiteBucketName'].OutputValue | [0]" --output text)"
distribution="$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDistributionId'].OutputValue | [0]" --output text)"
editor_bucket="$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='EditorBucketName'].OutputValue | [0]" --output text)"
editor_distribution="$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='EditorCloudFrontDistributionId'].OutputValue | [0]" --output text)"
api_url="$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue | [0]" --output text)"
events_table="$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='EventsTableName'].OutputValue | [0]" --output text)"
music_table="$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='MusicTableName'].OutputValue | [0]" --output text)"
text_table="$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='TextTableName'].OutputValue | [0]" --output text)"

EVENTS_TABLE_NAME="$events_table" \
MUSIC_TABLE_NAME="$music_table" \
TEXT_TABLE_NAME="$text_table" \
PREVIEW_NAME="Preview: $BRANCH_NAME" \
  "$ROOT_DIR/scripts/seed-preview-data.sh"

work_dir="$(mktemp -d)"
mkdir -p "$work_dir/site"
cp "$ROOT_DIR"/index.html "$ROOT_DIR"/about.html "$ROOT_DIR"/music.html "$ROOT_DIR"/shows.html "$ROOT_DIR"/services.html "$ROOT_DIR"/sitemap.xml "$work_dir/site/"
cp -R "$ROOT_DIR"/css "$ROOT_DIR"/partials "$ROOT_DIR"/photos "$ROOT_DIR"/videos "$work_dir/site/"
find "$work_dir/site" -type f -name "*.html" -print0 \
  | xargs -0 sed -i "s#https://api.sethcharleston.com/test1#${api_url}#g"

"$ROOT_DIR/scripts/publish-static-site.sh" "$work_dir/site" "$bucket" "$distribution"

"$ROOT_DIR/scripts/package-editor.sh" "$work_dir/editor"
find "$work_dir/editor" -type f \( -name "*.html" -o -name "*.js" \) -print0 \
  | xargs -0 sed -i \
      -e "s#https://api.sethcharleston.com/test1#${api_url}#g" \
      -e 's#https://login.sethcharleston.com/login?response_type=token&client_id=76g2um3ps3ri68ac30agopcmc9&redirect_uri=https://edit.sethcharleston.com#PREVIEW#g' \
      -e "s#https://sethcharleston.com#https://${domain_name}#g"
find "$work_dir/editor" -maxdepth 1 -type f -name "*.html" -print0 \
  | xargs -0 sed -i \
      -e "s#editor/inline-editor.css#editor/inline-editor.css?v=${editor_asset_version}#g" \
      -e "s#editor/inline-editor.js#editor/inline-editor.js?v=${editor_asset_version}#g"
"$ROOT_DIR/scripts/publish-static-site.sh" "$work_dir/editor" "$editor_bucket" "$editor_distribution"
curl --fail --silent --show-error --retry 5 --retry-delay 5 -H 'HX-Request: true' "${api_url}/text?view=home" >/dev/null
curl --fail --silent --show-error --retry 5 --retry-delay 10 --head "https://${domain_name}"
curl --fail --silent --show-error --retry 5 --retry-delay 10 --head "https://${editor_domain_name}"
echo "Preview deployed to https://${domain_name}, editor https://${editor_domain_name}, with isolated API ${api_url}"
