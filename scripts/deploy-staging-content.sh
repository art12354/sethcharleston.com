#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
SITE_DOMAIN="${SITE_DOMAIN:-staging.sethcharleston.com}"
API_DOMAIN="${API_DOMAIN:-api-staging.sethcharleston.com}"
EDITOR_DOMAIN="${EDITOR_DOMAIN:-edit-staging.sethcharleston.com}"
LOGIN_DOMAIN="${LOGIN_DOMAIN:-login-staging.sethcharleston.com}"
SITE_STACK_NAME="${SITE_STACK_NAME:-sethcharleston-staging-site}"
EDITOR_STACK_NAME="${EDITOR_STACK_NAME:-sethcharleston-staging-editor-site}"
BACKEND_STACK_NAME="${BACKEND_STACK_NAME:-sethcharleston-staging-backend}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EDITOR_ROOT="${EDITOR_ROOT:-/home/art12354/Projects/edit.sethcharleston.com}"
WORK_DIR="$(mktemp -d)"

stack_output() {
  local stack="$1"
  local key="$2"
  aws cloudformation describe-stacks \
    --stack-name "$stack" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='${key}'].OutputValue | [0]" \
    --output text
}

SITE_DISTRIBUTION_ID="$(stack_output "$SITE_STACK_NAME" CloudFrontDistributionId)"
EDITOR_DISTRIBUTION_ID="$(stack_output "$EDITOR_STACK_NAME" CloudFrontDistributionId)"
COGNITO_CLIENT_ID="$(stack_output "$BACKEND_STACK_NAME" UserPoolClientId)"

mkdir -p "$WORK_DIR/site" "$WORK_DIR/editor"

cp "$ROOT_DIR"/index.html "$ROOT_DIR"/about.html "$ROOT_DIR"/music.html "$ROOT_DIR"/shows.html "$ROOT_DIR"/sitemap.xml "$WORK_DIR/site/"
cp -R "$ROOT_DIR"/css "$ROOT_DIR"/photos "$ROOT_DIR"/videos "$WORK_DIR/site/"
find "$WORK_DIR/site" -type f -name "*.html" -print0 \
  | xargs -0 sed -i "s#https://api.sethcharleston.com#https://${API_DOMAIN}#g"

aws s3 sync "$WORK_DIR/site/" "s3://${SITE_DOMAIN}/" --delete
aws cloudfront create-invalidation --distribution-id "$SITE_DISTRIBUTION_ID" --paths "/*" >/dev/null

cp "$EDITOR_ROOT"/index.html "$WORK_DIR/editor/"
cp -R "$EDITOR_ROOT"/js "$WORK_DIR/editor/"
find "$WORK_DIR/editor" -type f \( -name "*.html" -o -name "*.js" \) -print0 \
  | xargs -0 sed -i "s#https://api.sethcharleston.com#https://${API_DOMAIN}#g"
find "$WORK_DIR/editor" -type f \( -name "*.html" -o -name "*.js" \) -print0 \
  | xargs -0 sed -i "s#https://login.sethcharleston.com#https://${LOGIN_DOMAIN}#g"
find "$WORK_DIR/editor" -type f \( -name "*.html" -o -name "*.js" \) -print0 \
  | xargs -0 sed -i "s#client_id=76g2um3ps3ri68ac30agopcmc9#client_id=${COGNITO_CLIENT_ID}#g"
find "$WORK_DIR/editor" -type f \( -name "*.html" -o -name "*.js" \) -print0 \
  | xargs -0 sed -i "s#redirect_uri=https://edit.sethcharleston.com#redirect_uri=https://${EDITOR_DOMAIN}#g"

aws s3 sync "$WORK_DIR/editor/" "s3://${EDITOR_DOMAIN}/" --delete
aws cloudfront create-invalidation --distribution-id "$EDITOR_DISTRIBUTION_ID" --paths "/*" >/dev/null

rm -rf "$WORK_DIR"
echo "Deployed staging content to https://${SITE_DOMAIN} and https://${EDITOR_DOMAIN}."
