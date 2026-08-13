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

find "$DESTINATION" -maxdepth 1 -type f -name "*.html" -print0 | while IFS= read -r -d '' page; do
  sed -i \
    -e 's#</head>#  <link rel="stylesheet" href="editor/inline-editor.css">\n</head>#' \
    -e 's#</body>#  <script src="editor/inline-editor.js"></script>\n</body>#' \
    "$page"
done
