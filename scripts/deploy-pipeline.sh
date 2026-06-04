#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_FILE="$ROOT_DIR/infra/cloudformation/codepipeline.yaml"

STACK_NAME="${STACK_NAME:-sethcharleston-codepipeline}"
AWS_REGION="${AWS_REGION:-us-east-1}"
PIPELINE_NAME="${PIPELINE_NAME:-sethcharleston.com}"
BUILD_PROJECT_NAME="${BUILD_PROJECT_NAME:-$(printf '%s-package' "$PIPELINE_NAME" | tr '.' '-' | tr -c '[:alnum:]_-' '-')}"
GITHUB_OWNER="${GITHUB_OWNER:-art12354}"
GITHUB_REPO="${GITHUB_REPO:-sethcharleston.com}"
GITHUB_BRANCH="${GITHUB_BRANCH:-master}"
SOURCE_PROVIDER="${SOURCE_PROVIDER:-GitHub}"
CODECOMMIT_REPOSITORY_NAME="${CODECOMMIT_REPOSITORY_NAME:-$GITHUB_REPO}"
CODECOMMIT_BRANCH="${CODECOMMIT_BRANCH:-$GITHUB_BRANCH}"
CONNECTION_ARN="${CONNECTION_ARN:-arn:aws:codestar-connections:us-east-1:305372771047:connection/6ac1a538-e4aa-4c85-9dce-4b2797063880}"
WEBSITE_BUCKET_NAME="${WEBSITE_BUCKET_NAME:-sethcharleston.com}"
INVALIDATION_FUNCTION_NAME="${INVALIDATION_FUNCTION_NAME:-seth_charleston_invalidate_cdn}"
CLOUDFRONT_DISTRIBUTION_ID="${CLOUDFRONT_DISTRIBUTION_ID:-E3FWVWV0D2QOJ4}"
API_BASE_URL="${API_BASE_URL:-https://api.sethcharleston.com}"
LOGIN_BASE_URL="${LOGIN_BASE_URL:-https://login.sethcharleston.com}"
COGNITO_CLIENT_ID="${COGNITO_CLIENT_ID:-76g2um3ps3ri68ac30agopcmc9}"
EDITOR_CALLBACK_URL="${EDITOR_CALLBACK_URL:-https://edit.sethcharleston.com}"
START_ON_SOURCE_CHANGE="${START_ON_SOURCE_CHANGE:-true}"
REQUIRE_MANUAL_APPROVAL="${REQUIRE_MANUAL_APPROVAL:-false}"

if [[ "$SOURCE_PROVIDER" == "GitHub" ]]; then
  connection_status="$(
    aws codestar-connections get-connection \
      --connection-arn "$CONNECTION_ARN" \
      --region "$AWS_REGION" \
      --query "Connection.ConnectionStatus" \
      --output text 2>/dev/null || true
  )"

  if [[ "$connection_status" != "AVAILABLE" ]]; then
    echo "GitHub connection is '$connection_status', not AVAILABLE: $CONNECTION_ARN" >&2
    echo "Authorize it in the AWS Console under Developer Tools > Connections, then rerun this script." >&2
    exit 1
  fi
fi

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "$TEMPLATE_FILE" \
  --region "$AWS_REGION" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    PipelineName="$PIPELINE_NAME" \
    BuildProjectName="$BUILD_PROJECT_NAME" \
    GitHubOwner="$GITHUB_OWNER" \
    GitHubRepo="$GITHUB_REPO" \
    GitHubBranch="$GITHUB_BRANCH" \
    SourceProvider="$SOURCE_PROVIDER" \
    CodeCommitRepositoryName="$CODECOMMIT_REPOSITORY_NAME" \
    CodeCommitBranch="$CODECOMMIT_BRANCH" \
    ConnectionArn="$CONNECTION_ARN" \
    WebsiteBucketName="$WEBSITE_BUCKET_NAME" \
    InvalidationFunctionName="$INVALIDATION_FUNCTION_NAME" \
    CloudFrontDistributionId="$CLOUDFRONT_DISTRIBUTION_ID" \
    ApiBaseUrl="$API_BASE_URL" \
    LoginBaseUrl="$LOGIN_BASE_URL" \
    CognitoClientId="$COGNITO_CLIENT_ID" \
    EditorCallbackUrl="$EDITOR_CALLBACK_URL" \
    StartOnSourceChange="$START_ON_SOURCE_CHANGE" \
    RequireManualApproval="$REQUIRE_MANUAL_APPROVAL" \
  --tags \
    Project=sethcharleston \
    ManagedBy=cloudformation \
  --no-fail-on-empty-changeset

aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query "Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}" \
  --output table
