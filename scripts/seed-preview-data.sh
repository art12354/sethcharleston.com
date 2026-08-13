#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="${AWS_REGION:-us-east-1}"
EVENTS_TABLE_NAME="${EVENTS_TABLE_NAME:?Set EVENTS_TABLE_NAME}"
MUSIC_TABLE_NAME="${MUSIC_TABLE_NAME:?Set MUSIC_TABLE_NAME}"
TEXT_TABLE_NAME="${TEXT_TABLE_NAME:?Set TEXT_TABLE_NAME}"
PREVIEW_NAME="${PREVIEW_NAME:-Feature preview}"

put_if_missing() {
  local table_name="$1"
  local key_name="$2"
  local item="$3"
  local result
  if ! result="$(aws dynamodb put-item \
      --region "$AWS_REGION" \
      --table-name "$table_name" \
      --item "$item" \
      --condition-expression "attribute_not_exists(#key)" \
      --expression-attribute-names "{\"#key\":\"${key_name}\"}" 2>&1)"; then
    if [[ "$result" != *ConditionalCheckFailedException* ]]; then
      echo "$result" >&2
      return 1
    fi
  fi
  return 0
}

put_if_missing "$EVENTS_TABLE_NAME" event "{\"event\":{\"S\":\"preview-show\"},\"name\":{\"S\":\"Preview Show\"},\"when\":{\"S\":\"2028-01-01T19:00:00-08:00\"},\"where\":{\"S\":\"Preview Venue\"},\"tickets\":{\"S\":\"https://example.com\"}}"
put_if_missing "$MUSIC_TABLE_NAME" song '{"song":{"S":"Preview Track"},"release":{"S":"2028-01-01T00:00:00-08:00"},"link":{"S":"<iframe title=\"Preview track\" src=\"https://open.spotify.com/embed/artist/1A5BJhYP6UBWnqVhuJnTqy\" height=\"352\" allow=\"autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture\" loading=\"lazy\"></iframe>"}}'
put_if_missing "$TEXT_TABLE_NAME" location "{\"location\":{\"S\":\"frontPageHeader\"},\"text\":{\"S\":\"${PREVIEW_NAME}\"}}"
put_if_missing "$TEXT_TABLE_NAME" location '{"location":{"S":"frontPageText"},"text":{"S":"This content comes from this branch’s isolated DynamoDB tables."}}'
put_if_missing "$TEXT_TABLE_NAME" location '{"location":{"S":"frontPageVideo"},"text":{"S":"<iframe class=\"featured-video\" src=\"https://www.youtube.com/embed/ozgBy7SskOg?si=Q-nr8v87JbiXua-z\" title=\"Seth Charleston newest video\" allow=\"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share\" referrerpolicy=\"strict-origin-when-cross-origin\" allowfullscreen></iframe>"}}'

# Upgrade the original empty preview seed without overwriting edited branch content.
if ! result="$(aws dynamodb update-item \
    --region "$AWS_REGION" \
    --table-name "$TEXT_TABLE_NAME" \
    --key '{"location":{"S":"frontPageVideo"}}' \
    --update-expression 'SET #text = :video' \
    --condition-expression '#text = :empty' \
    --expression-attribute-names '{"#text":"text"}' \
    --expression-attribute-values '{":empty":{"S":""},":video":{"S":"<iframe class=\"featured-video\" src=\"https://www.youtube.com/embed/ozgBy7SskOg?si=Q-nr8v87JbiXua-z\" title=\"Seth Charleston newest video\" allow=\"accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share\" referrerpolicy=\"strict-origin-when-cross-origin\" allowfullscreen></iframe>"}}' 2>&1)"; then
  if [[ "$result" != *ConditionalCheckFailedException* ]]; then
    echo "$result" >&2
    exit 1
  fi
fi
true
put_if_missing "$TEXT_TABLE_NAME" location '{"location":{"S":"bio"},"text":{"S":"This biography is isolated to the current feature preview."}}'
put_if_missing "$TEXT_TABLE_NAME" location '{"location":{"S":"services"},"text":{"S":"[{\"title\":\"Production\",\"description\":\"Shape your song from arrangement through tracking.\"},{\"title\":\"Mixing\",\"description\":\"Bring clarity, depth, and energy to every element.\"},{\"title\":\"Mastering\",\"description\":\"Prepare a polished, consistent master for release.\"}]"}}'

echo "Seeded isolated preview tables without replacing existing records."
