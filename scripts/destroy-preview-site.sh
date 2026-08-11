#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
BRANCH_NAME="${BRANCH_NAME:?Set BRANCH_NAME to the deleted branch name.}"

slug="$(
  printf '%s' "$BRANCH_NAME" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's#[^a-z0-9]+#-#g; s#^-+##; s#-+$##; s#-{2,}#-#g' \
    | cut -c1-42
)"

if [[ -z "$slug" || "$slug" == "master" || "$slug" == "main" ]]; then
  echo "Refusing to delete reserved preview '$slug'." >&2
  exit 1
fi

stack_name="sethcharleston-preview-${slug}"
if ! aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" >/dev/null 2>&1; then
  echo "Preview stack '$stack_name' does not exist."
  exit 0
fi

bucket="$(aws cloudformation describe-stacks --stack-name "$stack_name" --region "$AWS_REGION" --query "Stacks[0].Outputs[?OutputKey=='SiteBucketName'].OutputValue | [0]" --output text)"
aws s3 rm "s3://${bucket}/" --recursive --only-show-errors
aws cloudformation delete-stack --stack-name "$stack_name" --region "$AWS_REGION"
aws cloudformation wait stack-delete-complete --stack-name "$stack_name" --region "$AWS_REGION"
echo "Deleted preview for '$BRANCH_NAME'."
