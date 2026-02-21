#!/bin/bash
# generate_icon.sh

ICON_SRC="../monitra_virtual.png"
ICONSET_DIR="MonitraVirtual.iconset"

if [ ! -f "$ICON_SRC" ]; then
    echo "Error: $ICON_SRC not found!"
    exit 1
fi

mkdir -p "$ICONSET_DIR"

sips -z 16 16     "$ICON_SRC" --out "${ICONSET_DIR}/icon_16x16.png"
sips -z 32 32     "$ICON_SRC" --out "${ICONSET_DIR}/icon_16x16@2x.png"
sips -z 32 32     "$ICON_SRC" --out "${ICONSET_DIR}/icon_32x32.png"
sips -z 64 64     "$ICON_SRC" --out "${ICONSET_DIR}/icon_32x32@2x.png"
sips -z 128 128   "$ICON_SRC" --out "${ICONSET_DIR}/icon_128x128.png"
sips -z 256 256   "$ICON_SRC" --out "${ICONSET_DIR}/icon_128x128@2x.png"
sips -z 256 256   "$ICON_SRC" --out "${ICONSET_DIR}/icon_256x256.png"
sips -z 512 512   "$ICON_SRC" --out "${ICONSET_DIR}/icon_256x256@2x.png"
sips -z 512 512   "$ICON_SRC" --out "${ICONSET_DIR}/icon_512x512.png"
sips -z 1024 1024 "$ICON_SRC" --out "${ICONSET_DIR}/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_DIR" -o AppIcon.icns
rm -rf "$ICONSET_DIR"

echo "AppIcon.icns generated successfully."
