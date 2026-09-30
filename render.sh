#!/bin/bash
# Redraws the wallpapers in backgrounds/ from mcp.txt.
#
#   ./render.sh                 # the MCP greets ED, as in the film
#   NAME=FLYNN ./render.sh      # the MCP greets you instead
#
# Needs ImageMagick 7 (`magick`) and JetBrainsMono Nerd Font, both stock on Omarchy.
set -euo pipefail

BG='#0A0F0E'     # screen black  (colors.toml: background)
MAIN='#8AF0A8'   # phosphor      (colors.toml: accent)
DIM='#3f6e52'    # footer text

NAME=${NAME:-ED}
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=$HERE/backgrounds
F=/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf
FB=/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf
W=1920 H=1200

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

# Glow, scanlines and vignette over a transparent text layer.
crt() {
  magick -size ${W}x${H} xc:"$BG" \
    \( "$1" -channel A -blur 0x10 -evaluate multiply 0.9 +channel \) -compose screen -composite \
    \( "$1" -channel A -blur 0x2.5 +channel \) -compose screen -composite \
    "$1" -compose over -composite \
    \( -size 1x3 xc:none -fill 'rgba(0,0,0,0.3)' -draw 'point 0,2' -write mpr:s +delete -size ${W}x${H} tile:mpr:s \) -compose over -composite \
    \( -size 2400x1500 radial-gradient:'rgba(0,0,0,0)'-'rgba(0,0,0,0.6)' -gravity center -crop ${W}x${H}+0+0 +repage \) -compose over -composite \
    -quality 95 "$2"
}

# 1: the MCP session
sed "s/{NAME}/$NAME/g" "$HERE/mcp.txt" >"$TMP/mcp.txt"
magick -size ${W}x${H} xc:none -font $F -pointsize 26 -interline-spacing 4 -fill "$MAIN" -annotate +200+150 @"$TMP/mcp.txt" \
  -fill "$DIM" -pointsize 18 -annotate +200+1140 'ENCOM 511  //  (C) 1982 ENCOM INTERNATIONAL  //  UNAUTHORIZED USE IS PROHIBITED' "$TMP/t1.png"
crt "$TMP/t1.png" "$OUT/1-master-control.jpg"

# 2: the ENCOM wordmark, stretched wide and cut by three horizontal bands
magick -background none -fill "$MAIN" -font $FB -pointsize 260 label:'ENCOM' -trim +repage -resize 190%x100%\! "$TMP/logo.png"
read -r LW LH < <(magick identify -format '%w %h\n' "$TMP/logo.png")
magick -size ${LW}x${LH} xc:none -fill black \
  -draw "rectangle 0,$((LH*30/100)) $LW,$((LH*34/100))" \
  -draw "rectangle 0,$((LH*47/100)) $LW,$((LH*53/100))" \
  -draw "rectangle 0,$((LH*66/100)) $LW,$((LH*70/100))" "$TMP/bands.png"
magick "$TMP/logo.png" "$TMP/bands.png" -compose dst_out -composite "$TMP/logo.png"
magick -size ${W}x${H} xc:none "$TMP/logo.png" -gravity center -geometry +0-40 -compose over -composite \
  -font $F -fill "$DIM" -pointsize 22 -gravity center -annotate +0+$((LH/2+30)) 'I N T E R N A T I O N A L' \
  -gravity southwest -pointsize 18 -annotate +200+42 'ENCOM 511  //  MASTER CONTROL PROGRAM ONLINE  //  END OF LINE.' "$TMP/t2.png"
crt "$TMP/t2.png" "$OUT/2-encom-logo.jpg"

magick "$OUT/1-master-control.jpg" -resize 1200x "$HERE/preview.png"
echo "Rendered backgrounds for $NAME."
