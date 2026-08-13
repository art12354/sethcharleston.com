#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

node --check "$ROOT_DIR/editor/js/inline-editor.js"
for script in "$ROOT_DIR"/scripts/*.sh; do bash -n "$script"; done

aws cloudformation validate-template --template-body "file://$ROOT_DIR/infra/cloudformation/backend-api.yaml" >/dev/null
aws cloudformation validate-template --template-body "file://$ROOT_DIR/infra/cloudformation/preview-static-site.yaml" >/dev/null
aws cloudformation validate-template --template-body "file://$ROOT_DIR/infra/cloudformation/static-site.yaml" >/dev/null

if git -C "$ROOT_DIR" diff --check | grep -q .; then
  git -C "$ROOT_DIR" diff --check
  exit 1
fi

for page in index about music shows services; do
  grep -q 'partials/nav.html' "$ROOT_DIR/$page.html"
  grep -q 'partials/footer.html' "$ROOT_DIR/$page.html"
  grep -q 'src="js/htmx.min.js?v=2.0.10"' "$ROOT_DIR/$page.html"
done

test -s "$ROOT_DIR/js/htmx.min.js"
if grep -R -q 'cdn.jsdelivr.net/npm/htmx' "$ROOT_DIR"/*.html; then
  echo "HTMX must be served from the site, not a CDN." >&2
  exit 1
fi

grep -q '/media/library' "$ROOT_DIR/infra/cloudformation/backend-api.yaml"
grep -q 'render_songs' "$ROOT_DIR/infra/cloudformation/production-media-api.yaml"
grep -q 'put_method "$songs_id" GET NONE' "$ROOT_DIR/scripts/deploy-production-media-api.sh"
grep -q 'AuthorizationType: COGNITO_USER_POOLS' "$ROOT_DIR/infra/cloudformation/backend-api.yaml"
grep -q -- '--exclude "uploads/\*"' "$ROOT_DIR/scripts/publish-static-site.sh"

echo "Release validation passed."
