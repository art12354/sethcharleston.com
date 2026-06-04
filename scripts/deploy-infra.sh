#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE_FILE="$ROOT_DIR/infra/cloudformation/static-site.yaml"

STACK_NAME="${STACK_NAME:-sethcharleston-static-site}"
AWS_REGION="${AWS_REGION:-us-east-1}"
DOMAIN_NAME="${DOMAIN_NAME:-sethcharleston.com}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-}"
ACM_CERTIFICATE_ARN="${ACM_CERTIFICATE_ARN:-arn:aws:acm:us-east-1:305372771047:certificate/2db52ae6-5372-472a-b689-42126941926a}"
PRICE_CLASS="${PRICE_CLASS:-PriceClass_100}"
MANAGE_DNS_RECORDS="${MANAGE_DNS_RECORDS:-false}"
INCLUDE_WWW_ALIAS="${INCLUDE_WWW_ALIAS:-true}"

if [[ -z "$HOSTED_ZONE_ID" && -n "$DOMAIN_NAME" ]]; then
  HOSTED_ZONE_ID="$(
    aws route53 list-hosted-zones-by-name \
      --dns-name "$DOMAIN_NAME" \
      --query "HostedZones[?Name == '${DOMAIN_NAME}.'] | [?Config.PrivateZone == \`false\`] | [0].Id" \
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
  --parameter-overrides \
    DomainName="$DOMAIN_NAME" \
    HostedZoneId="$HOSTED_ZONE_ID" \
    AcmCertificateArn="$ACM_CERTIFICATE_ARN" \
    PriceClass="$PRICE_CLASS" \
    ManageDnsRecords="$MANAGE_DNS_RECORDS" \
    IncludeWwwAlias="$INCLUDE_WWW_ALIAS" \
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
