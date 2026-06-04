#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
HOSTED_ZONE_ID="${HOSTED_ZONE_ID:-Z27ZS6MVE7C6ZT}"
PRODUCTION_DOMAIN="${PRODUCTION_DOMAIN:-sethcharleston.com}"
TARGET_STACK_NAME="${TARGET_STACK_NAME:-}"
TARGET_CLOUDFRONT_DOMAIN="${TARGET_CLOUDFRONT_DOMAIN:-}"
TARGET_CLOUDFRONT_ZONE_ID="${TARGET_CLOUDFRONT_ZONE_ID:-Z2FDTNDATAQYW2}"

if [[ -z "$TARGET_CLOUDFRONT_DOMAIN" && -n "$TARGET_STACK_NAME" ]]; then
  TARGET_CLOUDFRONT_DOMAIN="$(
    aws cloudformation describe-stacks \
      --stack-name "$TARGET_STACK_NAME" \
      --region "$AWS_REGION" \
      --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDomainName'].OutputValue | [0]" \
      --output text
  )"
fi

if [[ -z "$TARGET_CLOUDFRONT_DOMAIN" || "$TARGET_CLOUDFRONT_DOMAIN" == "None" ]]; then
  echo "Set TARGET_CLOUDFRONT_DOMAIN or TARGET_STACK_NAME before cutting over DNS." >&2
  exit 1
fi

CHANGE_BATCH="$(mktemp)"
cat > "$CHANGE_BATCH" <<JSON
{
  "Comment": "Cut ${PRODUCTION_DOMAIN} to ${TARGET_CLOUDFRONT_DOMAIN}",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${PRODUCTION_DOMAIN}",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "${TARGET_CLOUDFRONT_ZONE_ID}",
          "DNSName": "${TARGET_CLOUDFRONT_DOMAIN}",
          "EvaluateTargetHealth": false
        }
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "www.${PRODUCTION_DOMAIN}",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "${TARGET_CLOUDFRONT_ZONE_ID}",
          "DNSName": "${TARGET_CLOUDFRONT_DOMAIN}",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
JSON

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch "file://$CHANGE_BATCH"

rm -f "$CHANGE_BATCH"
