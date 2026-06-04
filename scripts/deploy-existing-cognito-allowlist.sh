#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_FILE="$ROOT_DIR/infra/cloudformation/existing-cognito-allowlist.yaml"

STACK_NAME="${STACK_NAME:-sethcharleston-prod-cognito-allowlist}"
AWS_REGION="${AWS_REGION:-us-east-1}"
USER_POOL_ID="${USER_POOL_ID:-us-east-1_KyvNSufwI}"
FUNCTION_NAME="${FUNCTION_NAME:-sethcharleston-prod-admin-user-allowlist}"
ALLOWED_ADMIN_EMAILS="${ALLOWED_ADMIN_EMAILS:-art12354@gmail.com,seth.charleston@gmail.com}"

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "$TEMPLATE_FILE" \
  --region "$AWS_REGION" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    UserPoolId="$USER_POOL_ID" \
    FunctionName="$FUNCTION_NAME" \
    AllowedAdminEmails="$ALLOWED_ADMIN_EMAILS" \
  --tags \
    Project=sethcharleston \
    Environment=prod \
    ManagedBy=cloudformation \
  --no-fail-on-empty-changeset

aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query "Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}" \
  --output table
