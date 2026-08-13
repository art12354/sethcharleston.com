#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-Z27ZS6MVE7C6ZT}"
ACM_CERTIFICATE_ARN="${ACM_CERTIFICATE_ARN:-arn:aws:acm:us-east-1:305372771047:certificate/2db52ae6-5372-472a-b689-42126941926a}"

SITE_DOMAIN="${SITE_DOMAIN:-staging.sethcharleston.com}"
API_DOMAIN="${API_DOMAIN:-api-staging.sethcharleston.com}"
EDITOR_DOMAIN="${EDITOR_DOMAIN:-edit-staging.sethcharleston.com}"
LOGIN_DOMAIN="${LOGIN_DOMAIN:-login-staging.sethcharleston.com}"
ALLOWED_ADMIN_EMAILS="${ALLOWED_ADMIN_EMAILS:-art12354@gmail.com,seth.charleston@gmail.com}"

API_BASE_URL="https://${API_DOMAIN}"
LOGIN_BASE_URL="https://${LOGIN_DOMAIN}"
EDITOR_CALLBACK_URL="https://${EDITOR_DOMAIN}"

STACK_NAME=sethcharleston-staging-backend \
AWS_REGION="$AWS_REGION" \
PROJECT_NAME=sethcharleston \
ENVIRONMENT=staging \
API_DOMAIN_NAME="$API_DOMAIN" \
API_CERTIFICATE_ARN="$ACM_CERTIFICATE_ARN" \
HOSTED_AUTH_DOMAIN_NAME="$LOGIN_DOMAIN" \
EDITOR_CALLBACK_URL="$EDITOR_CALLBACK_URL" \
ALLOWED_ADMIN_EMAILS="$ALLOWED_ADMIN_EMAILS" \
EVENTS_TABLE_NAME=seth_charleston_staging_events \
MUSIC_TABLE_NAME=seth_charleston_staging_music \
TEXT_TABLE_NAME=seth_charleston_staging_text \
SITE_BUCKET_NAME="$SITE_DOMAIN" \
SITE_DOMAIN_NAME="$SITE_DOMAIN" \
HOSTED_ZONE_ID="$HOSTED_ZONE_ID" \
./scripts/deploy-backend.sh

STACK_NAME=sethcharleston-staging-site \
AWS_REGION="$AWS_REGION" \
DOMAIN_NAME="$SITE_DOMAIN" \
HOSTED_ZONE_ID="$HOSTED_ZONE_ID" \
ACM_CERTIFICATE_ARN="$ACM_CERTIFICATE_ARN" \
MANAGE_DNS_RECORDS=true \
INCLUDE_WWW_ALIAS=false \
./scripts/deploy-infra.sh

STACK_NAME=sethcharleston-staging-editor-site \
AWS_REGION="$AWS_REGION" \
DOMAIN_NAME="$EDITOR_DOMAIN" \
HOSTED_ZONE_ID="$HOSTED_ZONE_ID" \
ACM_CERTIFICATE_ARN="$ACM_CERTIFICATE_ARN" \
MANAGE_DNS_RECORDS=true \
INCLUDE_WWW_ALIAS=false \
./scripts/deploy-infra.sh

./scripts/seed-staging-data.sh
./scripts/deploy-staging-content.sh
./scripts/smoke-test-staging.sh
