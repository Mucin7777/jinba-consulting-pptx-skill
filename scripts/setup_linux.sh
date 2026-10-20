#!/usr/bin/env bash
# Linux（Claude Code のクラウド環境・Docker など）でパーツ集を正しい書体で描けるようにする。何度実行してもよい。
#   1. 和文フォント Noto CJK が無ければ入れる（apt-get。root か sudo が要る）
#   2. パーツ集の書体名（Yu Gothic・Yu Mincho・ヒラギノ・メイリオ）を Noto CJK JP に対応づける（scripts/fontconfig-ja.conf）
#      これが無いと、和文が中国語の字形（WenQuanYi など）で描かれ、見出しの明朝もゴシックになる
#   3. python-pptx が無ければ入れる（PPTX への変換・PPTX の検査に使う）
#   4. playwright（check_layout.mjs）と Chrome（html_to_pptx.py）が見つかるかを表示する
# 使い方: bash scripts/setup_linux.sh
set -uo pipefail

if [ "$(uname -s)" != "Linux" ]; then
  echo "Linux 用のスクリプト（Mac / Windows は README の「セットアップ」）"; exit 0
fi
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUDO=""; [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"

# 1. 和文フォント
if fc-list :lang=ja family 2>/dev/null | grep -q "Noto Sans CJK JP"; then
  echo "ok    Noto CJK"
elif command -v apt-get >/dev/null; then
  echo "...   fonts-noto-cjk を入れる"
  $SUDO apt-get install -y -q --no-install-recommends fonts-noto-cjk >/dev/null 2>&1 \
    || { $SUDO apt-get update -q >/dev/null 2>&1 && $SUDO apt-get install -y -q --no-install-recommends fonts-noto-cjk >/dev/null 2>&1; } \
    && echo "ok    Noto CJK" || echo "NG    fonts-noto-cjk を入れられなかった（ネットワーク・権限を確認）"
else
  echo "NG    Noto CJK が無い（ディストリのパッケージ管理で Noto Sans/Serif CJK JP を入れる）"
fi

# 2. 書体名の対応づけ
CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fontconfig/conf.d"
mkdir -p "$CONF_DIR"
cp "$ROOT/scripts/fontconfig-ja.conf" "$CONF_DIR/60-consulting-pptx-ja.conf"
fc-cache -f >/dev/null 2>&1 || true
case "$(fc-match "Yu Mincho" 2>/dev/null)" in
  *"Noto Serif CJK JP"*) echo "ok    Yu Gothic / Yu Mincho → Noto Sans / Serif CJK JP" ;;
  *) echo "NG    書体名の対応づけが効いていない（fc-match \"Yu Mincho\" を確認）" ;;
esac

# 3. python-pptx
if python3 -c "import pptx" 2>/dev/null; then
  echo "ok    python-pptx"
else
  python3 -m pip install -q python-pptx 2>/dev/null && echo "ok    python-pptx" \
    || echo "NG    python-pptx を入れられなかった（pip3 install python-pptx。PPTX を扱わないなら不要）"
fi

# 4. playwright と Chrome（探す順は check_layout.mjs・lib_cdp.mjs と同じ）
if [ -n "${PLAYWRIGHT_MODULE_DIR:-}" ] || [ -d "$ROOT/node_modules/playwright" ] \
   || { command -v npm >/dev/null && [ -d "$(npm root -g 2>/dev/null)/playwright" ]; }; then
  echo "ok    playwright（check_layout.mjs）"
else
  echo "NG    playwright が無い（リポ直下で npm run setup）"
fi
CHROME="${CHROME_PATH:-}"
for c in /usr/bin/google-chrome /usr/bin/google-chrome-stable /usr/bin/chromium /usr/bin/chromium-browser /opt/pw-browsers/chromium; do
  [ -z "$CHROME" ] && [ -x "$c" ] && CHROME="$c"
done
if [ -n "$CHROME" ]; then
  NOSB=""; [ "$(id -u)" -eq 0 ] && NOSB=" --no-sandbox"  # root では sandbox 無しでないと起動しない
  echo "ok    Chrome: $CHROME"
  echo "      PDF: \"$CHROME\" --headless$NOSB --disable-gpu --no-pdf-header-footer --print-to-pdf=deck.pdf deck.html"
else
  echo "NG    Chrome が無い（PDF 化・html_to_pptx.py に要る。CHROME_PATH で指定可）"
fi
