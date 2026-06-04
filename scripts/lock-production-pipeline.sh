#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
PIPELINE_NAME="${PIPELINE_NAME:-sethcharleston.com}"

aws codepipeline disable-stage-transition \
  --pipeline-name "$PIPELINE_NAME" \
  --stage-name Deploy \
  --transition-type Inbound \
  --reason "Production deploys are manual; main/master deploys to staging." \
  --region "$AWS_REGION"

echo "Disabled automatic transition into ${PIPELINE_NAME}:Deploy."
