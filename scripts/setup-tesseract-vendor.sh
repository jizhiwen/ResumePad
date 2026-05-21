#!/usr/bin/env sh
# 将 Tesseract.js 与离线语言包复制到 vendor/tesseract（供 Electron 使用，无需联网）
set -e
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
VENDOR="$ROOT/vendor/tesseract"
TESSDATA="$VENDOR/tessdata"

cd "$ROOT"
[ -d node_modules/tesseract.js ] || { echo "请先运行: npm install" >&2; exit 1; }

mkdir -p "$TESSDATA"
cp node_modules/tesseract.js/dist/tesseract.min.js "$VENDOR/"
cp node_modules/tesseract.js/dist/worker.min.js "$VENDOR/"
cp node_modules/tesseract.js-core/tesseract-core-lstm.wasm.js "$VENDOR/"
cp node_modules/tesseract.js-core/tesseract-core-lstm.wasm "$VENDOR/"
cp node_modules/tesseract.js-core/tesseract-core-simd-lstm.wasm.js "$VENDOR/" 2>/dev/null || true
cp node_modules/tesseract.js-core/tesseract-core-simd-lstm.wasm "$VENDOR/" 2>/dev/null || true

cp node_modules/@tesseract.js-data/chi_sim/4.0.0/chi_sim.traineddata.gz "$TESSDATA/"
cp node_modules/@tesseract.js-data/eng/4.0.0_best_int/eng.traineddata.gz "$TESSDATA/"

echo "Tesseract 离线资源: $VENDOR"
du -sh "$VENDOR" "$TESSDATA"
