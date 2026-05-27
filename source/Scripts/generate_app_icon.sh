#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_SVG="$ROOT_DIR/Assets/AppIcon/AppIcon.svg"
ICONSET="$ROOT_DIR/Resources/AppIcon.iconset"
OUTPUT="$ROOT_DIR/Resources/AppIcon.icns"

if ! command -v rsvg-convert >/dev/null 2>&1; then
  echo "rsvg-convert is required to render the app icon." >&2
  exit 1
fi

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

render_icon() {
  local points="$1"
  local scale="$2"
  local suffix="$3"
  local pixels=$((points * scale))
  rsvg-convert -w "$pixels" -h "$pixels" "$SOURCE_SVG" -o "$ICONSET/icon_${points}x${points}${suffix}.png"
}

render_icon 16 1 ""
render_icon 16 2 "@2x"
render_icon 32 1 ""
render_icon 32 2 "@2x"
render_icon 128 1 ""
render_icon 128 2 "@2x"
render_icon 256 1 ""
render_icon 256 2 "@2x"
render_icon 512 1 ""
render_icon 512 2 "@2x"

iconutil -c icns "$ICONSET" -o "$OUTPUT"
rm -rf "$ICONSET"
echo "$OUTPUT"
