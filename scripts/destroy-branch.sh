#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
BRANCH_NAME="${BRANCH_NAME:-$(git branch --show-current 2>/dev/null || true)}"

if [[ -z "$BRANCH_NAME" ]]; then
  echo "Set BRANCH_NAME or run from a git branch." >&2
  exit 1
fi

slug="$(
  printf '%s' "$BRANCH_NAME" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's#[^a-z0-9]+#-#g; s#^-+##; s#-+$##; s#-{2,}#-#g' \
    | cut -c1-42
)"

if [[ -z "$slug" || "$slug" == "master" || "$slug" == "main" ]]; then
  echo "Refusing to destroy reserved branch environment '$slug'." >&2
  exit 1
fi

for bucket in "${slug}.sethcharleston.com" "edit-${slug}.sethcharleston.com"; do
  if aws s3api head-bucket --bucket "$bucket" 2>/dev/null; then
    aws s3 rm "s3://${bucket}" --recursive
  fi
done

for stack in \
  "sethcharleston-branch-${slug}-editor-site" \
  "sethcharleston-branch-${slug}-site" \
  "sethcharleston-branch-${slug}-backend"
do
  if aws cloudformation describe-stacks --stack-name "$stack" --region "$AWS_REGION" >/dev/null 2>&1; then
    aws cloudformation delete-stack --stack-name "$stack" --region "$AWS_REGION"
  fi
done

echo "Delete requested for branch environment '$slug'."
