#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
PIPELINE_NAME="${PIPELINE_NAME:-sethcharleston.com}"

aws codepipeline enable-stage-transition \
  --pipeline-name "$PIPELINE_NAME" \
  --stage-name Deploy \
  --transition-type Inbound \
  --region "$AWS_REGION"

echo "Enabled transition into ${PIPELINE_NAME}:Deploy."
