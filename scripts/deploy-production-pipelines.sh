#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
PRODUCTION_BRANCH="${PRODUCTION_BRANCH:-master}"
PIPELINE_SOURCE_PROVIDER="${PIPELINE_SOURCE_PROVIDER:-CodeCommit}"

STACK_NAME=sethcharleston-production-site-pipeline \
PIPELINE_NAME=sethcharleston.com-production \
BUILD_PROJECT_NAME=sethcharleston-com-production-package \
SOURCE_PROVIDER="$PIPELINE_SOURCE_PROVIDER" \
GITHUB_BRANCH="$PRODUCTION_BRANCH" \
CODECOMMIT_REPOSITORY_NAME=sethcharleston.com \
CODECOMMIT_BRANCH="$PRODUCTION_BRANCH" \
WEBSITE_BUCKET_NAME=sethcharleston.com \
CLOUDFRONT_DISTRIBUTION_ID=E3FWVWV0D2QOJ4 \
API_BASE_URL=https://api.sethcharleston.com \
LOGIN_BASE_URL=https://login.sethcharleston.com \
COGNITO_CLIENT_ID=76g2um3ps3ri68ac30agopcmc9 \
EDITOR_CALLBACK_URL=https://edit.sethcharleston.com \
START_ON_SOURCE_CHANGE=false \
REQUIRE_MANUAL_APPROVAL=true \
AWS_REGION="$AWS_REGION" \
./scripts/deploy-pipeline.sh

STACK_NAME=sethcharleston-production-editor-pipeline \
PIPELINE_NAME=edit.sethcharleston.com-production \
BUILD_PROJECT_NAME=edit-sethcharleston-com-production-package \
SOURCE_PROVIDER="$PIPELINE_SOURCE_PROVIDER" \
GITHUB_REPO=edit.sethcharleston.com \
GITHUB_BRANCH="$PRODUCTION_BRANCH" \
CODECOMMIT_REPOSITORY_NAME=edit.sethcharleston.com \
CODECOMMIT_BRANCH="$PRODUCTION_BRANCH" \
WEBSITE_BUCKET_NAME=edit.sethcharleston.com \
CLOUDFRONT_DISTRIBUTION_ID=E2XF0OI690268U \
API_BASE_URL=https://api.sethcharleston.com \
LOGIN_BASE_URL=https://login.sethcharleston.com \
COGNITO_CLIENT_ID=76g2um3ps3ri68ac30agopcmc9 \
EDITOR_CALLBACK_URL=https://edit.sethcharleston.com \
START_ON_SOURCE_CHANGE=false \
REQUIRE_MANUAL_APPROVAL=true \
AWS_REGION="$AWS_REGION" \
./scripts/deploy-pipeline.sh
