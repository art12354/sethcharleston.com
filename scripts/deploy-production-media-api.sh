#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
REST_API_ID="${REST_API_ID:-ht1utrpnua}"
AUTHORIZER_ID="${AUTHORIZER_ID:-z3qept}"
STACK_NAME="${STACK_NAME:-sethcharleston-production-media-api}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

aws cloudformation deploy --stack-name "$STACK_NAME" --region "$AWS_REGION" \
  --template-file "$ROOT_DIR/infra/cloudformation/production-media-api.yaml" \
  --capabilities CAPABILITY_IAM --parameter-overrides RestApiId="$REST_API_ID" \
  --tags Project=sethcharleston Environment=production ManagedBy=cloudformation --no-fail-on-empty-changeset

function_arn="$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='FunctionArn'].OutputValue" --output text)"
root_id="$(aws apigateway get-resources --rest-api-id "$REST_API_ID" --limit 100 --query 'items[?path==`/`].id' --output text)"
resource_id() {
  local parent="$1" part="$2" path="$3" id
  id="$(aws apigateway get-resources --rest-api-id "$REST_API_ID" --limit 100 --query "items[?path=='${path}'].id" --output text)"
  [[ -n "$id" ]] || id="$(aws apigateway create-resource --rest-api-id "$REST_API_ID" --parent-id "$parent" --path-part "$part" --query id --output text)"
  printf '%s' "$id"
}
media_id="$(resource_id "$root_id" media /media)"
slot_id="$(resource_id "$media_id" '{slot}' '/media/{slot}')"
library_id="$(resource_id "$media_id" library /media/library)"
upload_id="$(resource_id "$media_id" upload /media/upload)"
commit_id="$(resource_id "$media_id" commit /media/commit)"
delete_id="$(resource_id "$media_id" delete /media/delete)"
uri="arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${function_arn}/invocations"

put_method() {
  local resource="$1" method="$2" auth="$3"
  local args=(--rest-api-id "$REST_API_ID" --resource-id "$resource" --http-method "$method" --authorization-type "$auth")
  [[ "$auth" == COGNITO_USER_POOLS ]] && args+=(--authorizer-id "$AUTHORIZER_ID")
  aws apigateway get-method --rest-api-id "$REST_API_ID" --resource-id "$resource" --http-method "$method" >/dev/null 2>&1 || aws apigateway put-method "${args[@]}" >/dev/null
  aws apigateway put-integration --rest-api-id "$REST_API_ID" --resource-id "$resource" --http-method "$method" --type AWS_PROXY --integration-http-method POST --uri "$uri" >/dev/null
}
put_method "$slot_id" GET NONE
put_method "$library_id" GET COGNITO_USER_POOLS
put_method "$upload_id" POST COGNITO_USER_POOLS
put_method "$commit_id" POST COGNITO_USER_POOLS
put_method "$delete_id" POST COGNITO_USER_POOLS

# The public HTMX pages need HTML fragments, while the editor still requests
# JSON from these same read routes. Route only GET through the compatible
# production function; the legacy authenticated write methods stay untouched.
songs_id="$(aws apigateway get-resources --rest-api-id "$REST_API_ID" --limit 100 --query 'items[?path==`/songs`].id' --output text)"
put_method "$root_id" GET NONE
put_method "$songs_id" GET NONE

put_options() {
  local resource="$1" methods="$2"
  local response_parameters
  response_parameters="{\"method.response.header.Access-Control-Allow-Headers\":\"'Content-Type,HX-Request,HX-Trigger,HX-Trigger-Name,HX-Target,HX-Current-URL,Authorization'\",\"method.response.header.Access-Control-Allow-Methods\":\"'${methods},OPTIONS'\",\"method.response.header.Access-Control-Allow-Origin\":\"'*'\"}"
  aws apigateway get-method --rest-api-id "$REST_API_ID" --resource-id "$resource" --http-method OPTIONS >/dev/null 2>&1 || aws apigateway put-method --rest-api-id "$REST_API_ID" --resource-id "$resource" --http-method OPTIONS --authorization-type NONE >/dev/null
  aws apigateway put-integration --rest-api-id "$REST_API_ID" --resource-id "$resource" --http-method OPTIONS --type MOCK --request-templates '{"application/json":"{\"statusCode\":200}"}' >/dev/null
  aws apigateway get-method-response --rest-api-id "$REST_API_ID" --resource-id "$resource" --http-method OPTIONS --status-code 200 >/dev/null 2>&1 || aws apigateway put-method-response --rest-api-id "$REST_API_ID" --resource-id "$resource" --http-method OPTIONS --status-code 200 --response-parameters method.response.header.Access-Control-Allow-Headers=true,method.response.header.Access-Control-Allow-Methods=true,method.response.header.Access-Control-Allow-Origin=true >/dev/null
  aws apigateway get-integration-response --rest-api-id "$REST_API_ID" --resource-id "$resource" --http-method OPTIONS --status-code 200 >/dev/null 2>&1 || aws apigateway put-integration-response --rest-api-id "$REST_API_ID" --resource-id "$resource" --http-method OPTIONS --status-code 200 --response-parameters "$response_parameters" >/dev/null
}
put_options "$slot_id" GET
put_options "$library_id" GET
put_options "$upload_id" POST
put_options "$commit_id" POST
put_options "$delete_id" POST
put_options "$root_id" GET
put_options "$songs_id" GET

deployment="$(aws apigateway create-deployment --rest-api-id "$REST_API_ID" --description "Media library release $(git -C "$ROOT_DIR" rev-parse --short HEAD)" --query id --output text)"
aws apigateway update-stage --rest-api-id "$REST_API_ID" --stage-name test1 --patch-operations op=replace,path=/deploymentId,value="$deployment" >/dev/null
echo "Production media API deployed."
