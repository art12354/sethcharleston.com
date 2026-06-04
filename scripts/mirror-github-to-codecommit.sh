#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
REPOSITORY_NAME="${REPOSITORY_NAME:-sethcharleston.com}"
PROJECT_NAME="${PROJECT_NAME:-sethcharleston-git-mirror}"

aws codebuild start-build \
  --project-name "$PROJECT_NAME" \
  --region "$AWS_REGION" \
  --environment-variables-override name=REPOSITORY_NAME,value="$REPOSITORY_NAME",type=PLAINTEXT \
  --query "build.{id:id,arn:arn}" \
  --output table
