#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AWS_REGION="${AWS_REGION:-us-east-1}"
STACK_NAME="${STACK_NAME:-sethcharleston-github-actions}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-art12354/sethcharleston.com}"

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "$ROOT_DIR/infra/cloudformation/github-actions-deploy.yaml" \
  --region "$AWS_REGION" \
  --capabilities CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset \
  --tags Project=sethcharleston Environment=production ManagedBy=cloudformation

deploy_role_arn="$(
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='DeployRoleArn'].OutputValue | [0]" \
    --output text
)"

preview_role_arn="$(
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='PreviewRoleArn'].OutputValue | [0]" \
    --output text
)"

set_repository_variable() {
  local name="$1"
  local value="$2"

  gh api \
    --method PATCH \
    -H "Accept: application/vnd.github+json" \
    "repos/${GITHUB_REPOSITORY}/actions/variables/${name}" \
    -f name="$name" \
    -f value="$value" >/dev/null 2>&1 || \
  gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    "repos/${GITHUB_REPOSITORY}/actions/variables" \
    -f name="$name" \
    -f value="$value" >/dev/null
}

set_repository_variable AWS_DEPLOY_ROLE_ARN "$deploy_role_arn"
set_repository_variable AWS_PREVIEW_ROLE_ARN "$preview_role_arn"

echo "Configured GitHub Actions deploy role: $deploy_role_arn"
echo "Configured GitHub Actions preview role: $preview_role_arn"
