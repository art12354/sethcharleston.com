#!/usr/bin/env bash
set -euo pipefail

SITE_DOMAIN="${SITE_DOMAIN:-staging.sethcharleston.com}"
API_DOMAIN="${API_DOMAIN:-api-staging.sethcharleston.com}"
EDITOR_DOMAIN="${EDITOR_DOMAIN:-edit-staging.sethcharleston.com}"

curl -fsS "https://${API_DOMAIN}/test1/" >/dev/null
curl -fsS "https://${API_DOMAIN}/test1/text" >/dev/null
curl -fsS "https://${API_DOMAIN}/test1/songs" >/dev/null
curl -fsSI "https://${SITE_DOMAIN}" >/dev/null
curl -fsSI "https://${EDITOR_DOMAIN}" >/dev/null

echo "Staging smoke tests passed."
