#!/usr/bin/env bash
# Monta la página de descargas de mundos (GitHub Pages) en una carpeta.
# Uso: GODOT=/ruta/a/godot tools/build_site.sh [carpeta_salida]   (por defecto build/site)
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT=${GODOT:-godot}
OUT=$(realpath -m "${1:-build/site}")
MODEL_VIEWER_VERSION=4.1.0

rm -rf "$OUT"
mkdir -p "$OUT/vendor"
cp site/index.html icon.svg "$OUT/"
touch "$OUT/.nojekyll"

# Mundos -> GLB, fotos 360° y worlds.json
"$GODOT" --headless -s tools/export_worlds.gd -- "$OUT"
test -s "$OUT/worlds.json"

# Visor 3D (model-viewer) servido desde la propia página, sin depender de un CDN
tmp=$(mktemp -d)
curl -fsSL "https://registry.npmjs.org/@google/model-viewer/-/model-viewer-${MODEL_VIEWER_VERSION}.tgz" | tar xz -C "$tmp"
cp "$tmp/package/dist/model-viewer.min.js" "$OUT/vendor/"
cp "$tmp/package/LICENSE" "$OUT/vendor/model-viewer-LICENSE.txt"
rm -rf "$tmp"
echo "Página lista en $OUT"
