#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
STACK_NAME="${STACK_NAME:-sethcharleston-staging-backend}"
ADMIN_EMAIL="${ADMIN_EMAIL:-}"

if [[ -z "$ADMIN_EMAIL" ]]; then
  echo "Set ADMIN_EMAIL to a whitelisted admin email address." >&2
  exit 1
fi

USER_POOL_ID="$(
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue | [0]" \
    --output text
)"

if [[ -z "$USER_POOL_ID" || "$USER_POOL_ID" == "None" ]]; then
  echo "Could not find UserPoolId output on stack $STACK_NAME." >&2
  exit 1
fi

if aws cognito-idp admin-get-user \
  --user-pool-id "$USER_POOL_ID" \
  --username "$ADMIN_EMAIL" \
  --region "$AWS_REGION" >/dev/null 2>&1
then
  aws cognito-idp admin-update-user-attributes \
    --user-pool-id "$USER_POOL_ID" \
    --username "$ADMIN_EMAIL" \
    --user-attributes Name=email,Value="$ADMIN_EMAIL" Name=email_verified,Value=true \
    --region "$AWS_REGION" >/dev/null
  echo "Updated verified email for existing admin user $ADMIN_EMAIL in $USER_POOL_ID."
else
  aws cognito-idp admin-create-user \
    --user-pool-id "$USER_POOL_ID" \
    --username "$ADMIN_EMAIL" \
    --user-attributes Name=email,Value="$ADMIN_EMAIL" Name=email_verified,Value=true \
    --region "$AWS_REGION" >/dev/null
  echo "Created admin user $ADMIN_EMAIL in $USER_POOL_ID."
fi

if [[ -n "${ADMIN_PASSWORD:-}" ]]; then
  aws cognito-idp admin-set-user-password \
    --user-pool-id "$USER_POOL_ID" \
    --username "$ADMIN_EMAIL" \
    --password "$ADMIN_PASSWORD" \
    --permanent \
    --region "$AWS_REGION" >/dev/null
  echo "Set permanent password for $ADMIN_EMAIL."
fi
