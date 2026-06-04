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

stack_output() {
  local stack="$1"
  local key="$2"
  aws cloudformation describe-stacks \
    --stack-name "$stack" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='${key}'].OutputValue | [0]" \
    --output text
}

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

if [[ "${DEPLOY_PIPELINES:-false}" == "true" ]]; then
  SITE_DISTRIBUTION_ID="$(stack_output sethcharleston-staging-site CloudFrontDistributionId)"
  EDITOR_DISTRIBUTION_ID="$(stack_output sethcharleston-staging-editor-site CloudFrontDistributionId)"
  COGNITO_CLIENT_ID="$(stack_output sethcharleston-staging-backend UserPoolClientId)"
  PIPELINE_SOURCE_PROVIDER="${PIPELINE_SOURCE_PROVIDER:-CodeCommit}"
  STAGING_BRANCH="${STAGING_BRANCH:-master}"

  STACK_NAME=sethcharleston-staging-site-pipeline \
  PIPELINE_NAME=sethcharleston.com-staging \
  BUILD_PROJECT_NAME=sethcharleston-com-staging-package \
  SOURCE_PROVIDER="$PIPELINE_SOURCE_PROVIDER" \
  GITHUB_BRANCH="$STAGING_BRANCH" \
  CODECOMMIT_REPOSITORY_NAME=sethcharleston.com \
  CODECOMMIT_BRANCH="$STAGING_BRANCH" \
  WEBSITE_BUCKET_NAME="$SITE_DOMAIN" \
  CLOUDFRONT_DISTRIBUTION_ID="$SITE_DISTRIBUTION_ID" \
  API_BASE_URL="$API_BASE_URL" \
  LOGIN_BASE_URL="$LOGIN_BASE_URL" \
  COGNITO_CLIENT_ID="$COGNITO_CLIENT_ID" \
  EDITOR_CALLBACK_URL="$EDITOR_CALLBACK_URL" \
  ./scripts/deploy-pipeline.sh

  STACK_NAME=sethcharleston-staging-editor-pipeline \
  PIPELINE_NAME=edit.sethcharleston.com-staging \
  BUILD_PROJECT_NAME=edit-sethcharleston-com-staging-package \
  SOURCE_PROVIDER="$PIPELINE_SOURCE_PROVIDER" \
  GITHUB_REPO=edit.sethcharleston.com \
  GITHUB_BRANCH=master \
  CODECOMMIT_REPOSITORY_NAME=edit.sethcharleston.com \
  CODECOMMIT_BRANCH=master \
  WEBSITE_BUCKET_NAME="$EDITOR_DOMAIN" \
  CLOUDFRONT_DISTRIBUTION_ID="$EDITOR_DISTRIBUTION_ID" \
  API_BASE_URL="$API_BASE_URL" \
  LOGIN_BASE_URL="$LOGIN_BASE_URL" \
  COGNITO_CLIENT_ID="$COGNITO_CLIENT_ID" \
  EDITOR_CALLBACK_URL="$EDITOR_CALLBACK_URL" \
  ./scripts/deploy-pipeline.sh
else
  echo "Skipped staging pipelines. Set DEPLOY_PIPELINES=true after authorizing the GitHub CodeConnection."
fi

./scripts/seed-staging-data.sh
./scripts/deploy-staging-content.sh
./scripts/smoke-test-staging.sh
