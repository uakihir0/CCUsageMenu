#!/bin/zsh

set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
source_png="$root_dir/Resources/AppIcon.png"
iconset_dir="$root_dir/Resources/AppIcon.xcassets/AppIcon.appiconset"
compiled_dir="$root_dir/.build/AppIconAssets"

mkdir -p "$iconset_dir"
mkdir -p "$compiled_dir"
CLANG_MODULE_CACHE_PATH="$root_dir/.build/IconModuleCache" \
    swift "$root_dir/Scripts/generate-app-icon.swift" "$source_png"

function resize_icon() {
    local pixels="$1"
    local filename="$2"
    sips -z "$pixels" "$pixels" "$source_png" \
        --out "$iconset_dir/$filename" >/dev/null
}

resize_icon 16 icon_16x16.png
resize_icon 32 icon_16x16@2x.png
resize_icon 32 icon_32x32.png
resize_icon 64 icon_32x32@2x.png
resize_icon 128 icon_128x128.png
resize_icon 256 icon_128x128@2x.png
resize_icon 256 icon_256x256.png
resize_icon 512 icon_256x256@2x.png
resize_icon 512 icon_512x512.png
resize_icon 1024 icon_512x512@2x.png

xcrun actool "$root_dir/Resources/AppIcon.xcassets" \
    --compile "$compiled_dir" \
    --platform macosx \
    --minimum-deployment-target 14.0 \
    --app-icon AppIcon \
    --output-partial-info-plist "$compiled_dir/Info.plist"

echo "$compiled_dir/Assets.car"
