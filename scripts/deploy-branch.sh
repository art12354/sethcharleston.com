#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-Z27ZS6MVE7C6ZT}"
ACM_CERTIFICATE_ARN="${ACM_CERTIFICATE_ARN:-arn:aws:acm:us-east-1:305372771047:certificate/2db52ae6-5372-472a-b689-42126941926a}"
BRANCH_NAME="${BRANCH_NAME:-$(git branch --show-current 2>/dev/null || true)}"

if [[ -z "$BRANCH_NAME" ]]; then
  echo "Set BRANCH_NAME or run from a git branch." >&2
  exit 1
fi

slug="$(
  printf '%s' "$BRANCH_NAME" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's#[^a-z0-9]+#-#g; s#^-+##; s#-+$##; s#-{2,}#-#g' \
    | cut -c1-42
)"

if [[ -z "$slug" || "$slug" == "master" || "$slug" == "main" ]]; then
  echo "Branch '$BRANCH_NAME' maps to reserved slug '$slug'. Use ./scripts/deploy-staging.sh for main/master." >&2
  exit 1
fi

table_slug="$(printf '%s' "$slug" | tr '-' '_')"
SITE_DOMAIN="${SITE_DOMAIN:-${slug}.sethcharleston.com}"
API_DOMAIN="${API_DOMAIN:-api-${slug}.sethcharleston.com}"
EDITOR_DOMAIN="${EDITOR_DOMAIN:-edit-${slug}.sethcharleston.com}"
LOGIN_DOMAIN="${LOGIN_DOMAIN:-login-${slug}.sethcharleston.com}"

BACKEND_STACK_NAME="${BACKEND_STACK_NAME:-sethcharleston-branch-${slug}-backend}"
SITE_STACK_NAME="${SITE_STACK_NAME:-sethcharleston-branch-${slug}-site}"
EDITOR_STACK_NAME="${EDITOR_STACK_NAME:-sethcharleston-branch-${slug}-editor-site}"

STACK_NAME="$BACKEND_STACK_NAME" \
AWS_REGION="$AWS_REGION" \
PROJECT_NAME=sethcharleston \
ENVIRONMENT="branch-${slug}" \
API_DOMAIN_NAME="$API_DOMAIN" \
API_CERTIFICATE_ARN="$ACM_CERTIFICATE_ARN" \
HOSTED_AUTH_DOMAIN_NAME="$LOGIN_DOMAIN" \
EDITOR_CALLBACK_URL="https://${EDITOR_DOMAIN}" \
EVENTS_TABLE_NAME="seth_charleston_${table_slug}_events" \
MUSIC_TABLE_NAME="seth_charleston_${table_slug}_music" \
TEXT_TABLE_NAME="seth_charleston_${table_slug}_text" \
HOSTED_ZONE_ID="$HOSTED_ZONE_ID" \
./scripts/deploy-backend.sh

STACK_NAME="$SITE_STACK_NAME" \
AWS_REGION="$AWS_REGION" \
DOMAIN_NAME="$SITE_DOMAIN" \
HOSTED_ZONE_ID="$HOSTED_ZONE_ID" \
ACM_CERTIFICATE_ARN="$ACM_CERTIFICATE_ARN" \
MANAGE_DNS_RECORDS=true \
INCLUDE_WWW_ALIAS=false \
./scripts/deploy-infra.sh

STACK_NAME="$EDITOR_STACK_NAME" \
AWS_REGION="$AWS_REGION" \
DOMAIN_NAME="$EDITOR_DOMAIN" \
HOSTED_ZONE_ID="$HOSTED_ZONE_ID" \
ACM_CERTIFICATE_ARN="$ACM_CERTIFICATE_ARN" \
MANAGE_DNS_RECORDS=true \
INCLUDE_WWW_ALIAS=false \
./scripts/deploy-infra.sh

AWS_REGION="$AWS_REGION" \
EVENTS_TABLE_NAME="seth_charleston_${table_slug}_events" \
MUSIC_TABLE_NAME="seth_charleston_${table_slug}_music" \
TEXT_TABLE_NAME="seth_charleston_${table_slug}_text" \
./scripts/seed-staging-data.sh

AWS_REGION="$AWS_REGION" \
SITE_DOMAIN="$SITE_DOMAIN" \
API_DOMAIN="$API_DOMAIN" \
EDITOR_DOMAIN="$EDITOR_DOMAIN" \
LOGIN_DOMAIN="$LOGIN_DOMAIN" \
SITE_STACK_NAME="$SITE_STACK_NAME" \
EDITOR_STACK_NAME="$EDITOR_STACK_NAME" \
BACKEND_STACK_NAME="$BACKEND_STACK_NAME" \
./scripts/deploy-staging-content.sh

SITE_DOMAIN="$SITE_DOMAIN" \
API_DOMAIN="$API_DOMAIN" \
EDITOR_DOMAIN="$EDITOR_DOMAIN" \
./scripts/smoke-test-staging.sh

cat <<EOF
Branch environment deployed for '$BRANCH_NAME':
  Site:   https://${SITE_DOMAIN}
  API:    https://${API_DOMAIN}/test1
  Editor: https://${EDITOR_DOMAIN}
  Login:  https://${LOGIN_DOMAIN}
EOF
