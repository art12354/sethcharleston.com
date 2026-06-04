#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_FILE="$ROOT_DIR/infra/cloudformation/backend-api.yaml"

STACK_NAME="${STACK_NAME:-sethcharleston-backend-api}"
AWS_REGION="${AWS_REGION:-us-east-1}"
PROJECT_NAME="${PROJECT_NAME:-sethcharleston}"
ENVIRONMENT="${ENVIRONMENT:-prod}"
API_DOMAIN_NAME="${API_DOMAIN_NAME:-api.sethcharleston.com}"
API_CERTIFICATE_ARN="${API_CERTIFICATE_ARN:-}"
HOSTED_AUTH_DOMAIN_NAME="${HOSTED_AUTH_DOMAIN_NAME:-}"
EDITOR_CALLBACK_URL="${EDITOR_CALLBACK_URL:-https://edit.sethcharleston.com}"
APEX_DOMAIN_NAME="${APEX_DOMAIN_NAME:-sethcharleston.com}"
EVENTS_TABLE_NAME="${EVENTS_TABLE_NAME:-seth_charleston_events}"
MUSIC_TABLE_NAME="${MUSIC_TABLE_NAME:-seth_charleston_music}"
TEXT_TABLE_NAME="${TEXT_TABLE_NAME:-seth_charleston_text}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-}"

if [[ -z "$HOSTED_ZONE_ID" && -n "$APEX_DOMAIN_NAME" ]]; then
  HOSTED_ZONE_ID="$(
    aws route53 list-hosted-zones-by-name \
      --dns-name "$APEX_DOMAIN_NAME" \
      --query "HostedZones[?Name == '${APEX_DOMAIN_NAME}.'] | [?Config.PrivateZone == \`false\`] | [0].Id" \
      --output text 2>/dev/null \
      | sed 's#^/hostedzone/##'
  )"

  if [[ "$HOSTED_ZONE_ID" == "None" ]]; then
    HOSTED_ZONE_ID=""
  fi
fi

aws cloudformation deploy \
  --stack-name "$STACK_NAME" \
  --template-file "$TEMPLATE_FILE" \
  --region "$AWS_REGION" \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    ProjectName="$PROJECT_NAME" \
    Environment="$ENVIRONMENT" \
    ApiDomainName="$API_DOMAIN_NAME" \
    ApiCertificateArn="$API_CERTIFICATE_ARN" \
    HostedAuthDomainName="$HOSTED_AUTH_DOMAIN_NAME" \
    EditorCallbackUrl="$EDITOR_CALLBACK_URL" \
    EventsTableName="$EVENTS_TABLE_NAME" \
    MusicTableName="$MUSIC_TABLE_NAME" \
    TextTableName="$TEXT_TABLE_NAME" \
    HostedZoneId="$HOSTED_ZONE_ID" \
  --tags \
    Project="$PROJECT_NAME" \
    Environment="$ENVIRONMENT" \
    ManagedBy=cloudformation \
  --no-fail-on-empty-changeset

aws cloudformation describe-stacks \
  --stack-name "$STACK_NAME" \
  --region "$AWS_REGION" \
  --query "Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}" \
  --output table
