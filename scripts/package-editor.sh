#!/usr/bin/env bash
set -euo pipefail

DESTINATION="${1:?Usage: package-editor.sh DESTINATION}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mkdir -p "$DESTINATION"
cp "$ROOT_DIR"/index.html "$ROOT_DIR"/about.html "$ROOT_DIR"/music.html "$ROOT_DIR"/shows.html "$ROOT_DIR"/services.html "$DESTINATION/"
cp -R "$ROOT_DIR/partials" "$DESTINATION/"
cp -R "$ROOT_DIR"/css "$ROOT_DIR"/photos "$ROOT_DIR"/videos "$DESTINATION/"
mkdir -p "$DESTINATION/editor"
cp "$ROOT_DIR/editor/css/inline-editor.css" "$DESTINATION/editor/"
cp "$ROOT_DIR/editor/js/inline-editor.js" "$DESTINATION/editor/"
cp "$ROOT_DIR/editor/editor-shell.html" "$DESTINATION/editor/"

find "$DESTINATION" -maxdepth 1 -type f -name "*.html" -print0 | while IFS= read -r -d '' page; do
  page_name="$(basename "$page")"
  view="${page_name%.html}"
  [[ "$view" == "index" ]] && view="home"
  shell="$(sed -e "s#EDITOR_PANEL_URL#https://api.sethcharleston.com/test1/text?view=editor-${view}#g" -e "s#LIVE_PAGE#https://sethcharleston.com/${page_name}#g" "$ROOT_DIR/editor/editor-shell.html")"
  shell="${shell//\\/\\\\}"
  shell="${shell//&/\\&}"
  shell="${shell//#/\\#}"
  shell="${shell//$'\n'/\\n}"
  sed -i \
    -e 's#</head>#  <link rel="stylesheet" href="editor/inline-editor.css">\n</head>#' \
    -e "s#</body>#${shell}\n  <script src=\"editor/inline-editor.js\"></script>\n</body>#" \
    "$page"
done
