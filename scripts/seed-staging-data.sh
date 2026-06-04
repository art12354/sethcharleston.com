#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
EVENTS_TABLE_NAME="${EVENTS_TABLE_NAME:-seth_charleston_staging_events}"
MUSIC_TABLE_NAME="${MUSIC_TABLE_NAME:-seth_charleston_staging_music}"
TEXT_TABLE_NAME="${TEXT_TABLE_NAME:-seth_charleston_staging_text}"

aws dynamodb put-item \
  --region "$AWS_REGION" \
  --table-name "$EVENTS_TABLE_NAME" \
  --item '{
    "event": {"S": "staging-smoke-test"},
    "name": {"S": "Staging Smoke Test Event"},
    "when": {"S": "Sat Jan 01 2028 19:00:00 GMT-0800 (Pacific Standard Time)"},
    "where": {"S": "Staging"},
    "tickets": {"S": "https://example.com"}
  }'

aws dynamodb put-item \
  --region "$AWS_REGION" \
  --table-name "$MUSIC_TABLE_NAME" \
  --item '{
    "song": {"S": "Staging Track"},
    "release": {"S": "Sat Jan 01 2028 00:00:00 GMT-0800 (Pacific Standard Time)"},
    "link": {"S": "<iframe src=\"https://open.spotify.com/embed/track/example\"></iframe>"}
  }'

aws dynamodb put-item \
  --region "$AWS_REGION" \
  --table-name "$TEXT_TABLE_NAME" \
  --item '{"location": {"S": "frontPageHeader"}, "text": {"S": "Staging"}}'

aws dynamodb put-item \
  --region "$AWS_REGION" \
  --table-name "$TEXT_TABLE_NAME" \
  --item '{"location": {"S": "frontPageText"}, "text": {"S": "This content is served by the staging API."}}'

aws dynamodb put-item \
  --region "$AWS_REGION" \
  --table-name "$TEXT_TABLE_NAME" \
  --item '{"location": {"S": "frontPageVideo"}, "text": {"S": ""}}'

aws dynamodb put-item \
  --region "$AWS_REGION" \
  --table-name "$TEXT_TABLE_NAME" \
  --item '{"location": {"S": "bio"}, "text": {"S": "Staging biography content."}}'
