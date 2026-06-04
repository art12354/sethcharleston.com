#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_FILE="$ROOT_DIR/infra/cloudformation/branch-preview-codebuild.yaml"

STACK_NAME="${STACK_NAME:-sethcharleston-branch-preview-automation}"
AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-sethcharleston-branch-preview}"
CODECOMMIT_REPOSITORY_NAME="${CODECOMMIT_REPOSITORY_NAME:-sethcharleston.com}"
STAGING_BRANCH="${STAGING_BRANCH:-master}"
EXCLUDED_BRANCHES="${EXCLUDED_BRANCHES:-main,master}"

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "$TEMPLATE_FILE" \
  --region "$AWS_REGION" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    ProjectName="$PROJECT_NAME" \
    CodeCommitRepositoryName="$CODECOMMIT_REPOSITORY_NAME" \
    StagingBranch="$STAGING_BRANCH" \
    ExcludedBranches="$EXCLUDED_BRANCHES" \
  --tags \
    Project=sethcharleston \
    ManagedBy=cloudformation \
  --no-fail-on-empty-changeset

aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query "Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}" \
  --output table
