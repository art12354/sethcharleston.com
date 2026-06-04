#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
SECRET_NAME="${SECRET_NAME:-sethcharleston/github/mirror-token}"

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
  echo "Set GITHUB_TOKEN before updating $SECRET_NAME." >&2
  exit 1
fi

aws secretsmanager put-secret-value \
  --secret-id "$SECRET_NAME" \
  --secret-string "$(GITHUB_TOKEN="$GITHUB_TOKEN" perl -MJSON::PP -e 'print encode_json({ token => $ENV{GITHUB_TOKEN} })')" \
  --region "$AWS_REGION" >/dev/null

echo "Updated $SECRET_NAME."
