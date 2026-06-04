#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
OUT_DIR="${OUT_DIR:-infra/import/exported-production}"

mkdir -p "$OUT_DIR"

aws s3api get-bucket-website --bucket sethcharleston.com >"${OUT_DIR}/s3-sethcharleston-website.json"
aws s3api get-bucket-policy --bucket sethcharleston.com >"${OUT_DIR}/s3-sethcharleston-policy.json"
aws s3api get-bucket-website --bucket edit.sethcharleston.com >"${OUT_DIR}/s3-edit-website.json" 2>/dev/null || true
aws s3api get-bucket-policy --bucket edit.sethcharleston.com >"${OUT_DIR}/s3-edit-policy.json" 2>/dev/null || true

aws cloudfront get-distribution-config --id E3FWVWV0D2QOJ4 >"${OUT_DIR}/cloudfront-site.json"
aws cloudfront get-distribution-config --id E2XF0OI690268U >"${OUT_DIR}/cloudfront-editor.json"

aws apigateway get-export \
  --rest-api-id ht1utrpnua \
  --stage-name test1 \
  --export-type swagger \
  --parameters extensions='apigateway' \
  "${OUT_DIR}/api-production-swagger.json" \
  --region "$AWS_REGION" >/dev/null

aws apigateway get-resources --rest-api-id ht1utrpnua --embed methods --region "$AWS_REGION" >"${OUT_DIR}/api-resources.json"
aws apigateway get-domain-name --domain-name api.sethcharleston.com --region "$AWS_REGION" >"${OUT_DIR}/api-domain.json"
aws apigateway get-base-path-mappings --domain-name api.sethcharleston.com --region "$AWS_REGION" >"${OUT_DIR}/api-base-path-mappings.json"

aws cognito-idp describe-user-pool --user-pool-id us-east-1_KyvNSufwI --region "$AWS_REGION" >"${OUT_DIR}/cognito-user-pool.json"
aws cognito-idp describe-user-pool-client --user-pool-id us-east-1_KyvNSufwI --client-id 76g2um3ps3ri68ac30agopcmc9 --region "$AWS_REGION" >"${OUT_DIR}/cognito-user-pool-client.json"

for table in seth_charleston_events seth_charleston_music seth_charleston_text; do
  aws dynamodb describe-table --table-name "$table" --region "$AWS_REGION" >"${OUT_DIR}/dynamodb-${table}.json"
done

for fn in \
  seth_charleston_get_events \
  seth_charleston_post_events \
  seth_charleston_delete_events \
  seth_charleston_get_songs \
  seth_charleston_post_song \
  seth_charleston_delete_songs \
  seth_charleston_get_text \
  seth_charleston_post_text \
  seth_charleston_invalidate_cdn
do
  aws lambda get-function-configuration --function-name "$fn" --region "$AWS_REGION" >"${OUT_DIR}/lambda-${fn}.json"
done

echo "Exported production inventory to ${OUT_DIR}."
