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
WORK_DIR="$(mktemp -d)"
trap 'find "$WORK_DIR" -depth -delete 2>/dev/null || true' EXIT

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

mkdir -p "$WORK_DIR/site"
cp "$ROOT_DIR"/index.html "$ROOT_DIR"/about.html "$ROOT_DIR"/music.html "$ROOT_DIR"/shows.html "$ROOT_DIR"/services.html "$ROOT_DIR"/sitemap.xml "$WORK_DIR/site/"
cp -R "$ROOT_DIR/partials" "$WORK_DIR/site/"
cp -R "$ROOT_DIR"/css "$ROOT_DIR"/js "$ROOT_DIR"/photos "$ROOT_DIR"/videos "$WORK_DIR/site/"
find "$WORK_DIR/site" -type f -name "*.html" -print0 \
  | xargs -0 sed -i "s#https://api.sethcharleston.com#https://${API_DOMAIN}#g"

"$ROOT_DIR/scripts/publish-static-site.sh" "$WORK_DIR/site" "$SITE_DOMAIN" "$SITE_DISTRIBUTION_ID" >/dev/null
find "$WORK_DIR/site" -depth -delete

"$ROOT_DIR/scripts/package-editor.sh" "$WORK_DIR/editor"
find "$WORK_DIR/editor" -type f \( -name "*.html" -o -name "*.js" \) -print0 \
  | xargs -0 sed -i "s#https://api.sethcharleston.com#https://${API_DOMAIN}#g"
find "$WORK_DIR/editor" -type f \( -name "*.html" -o -name "*.js" \) -print0 \
  | xargs -0 sed -i "s#https://login.sethcharleston.com#https://${LOGIN_DOMAIN}#g"
find "$WORK_DIR/editor" -type f \( -name "*.html" -o -name "*.js" \) -print0 \
  | xargs -0 sed -i "s#client_id=76g2um3ps3ri68ac30agopcmc9#client_id=${COGNITO_CLIENT_ID}#g"
find "$WORK_DIR/editor" -type f \( -name "*.html" -o -name "*.js" \) -print0 \
  | xargs -0 sed -i "s#redirect_uri=https://edit.sethcharleston.com#redirect_uri=https://${EDITOR_DOMAIN}#g"
find "$WORK_DIR/editor" -type f -name "*.js" -print0 \
  | xargs -0 sed -i "s#https://sethcharleston.com#https://${SITE_DOMAIN}#g"

"$ROOT_DIR/scripts/publish-static-site.sh" "$WORK_DIR/editor" "$EDITOR_DOMAIN" "$EDITOR_DISTRIBUTION_ID" >/dev/null
echo "Deployed staging content to https://${SITE_DOMAIN} and https://${EDITOR_DOMAIN}."
