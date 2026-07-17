#!/bin/zsh

set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
configuration="${CONFIGURATION:-release}"
app_dir="$root_dir/.build/CCUsageMenu.app"

"$root_dir/Scripts/build-icon.sh"

swift build \
    --package-path "$root_dir" \
    --configuration "$configuration"

bin_dir="$(swift build \
    --package-path "$root_dir" \
    --configuration "$configuration" \
    --show-bin-path)"

mkdir -p "$app_dir/Contents/MacOS"
mkdir -p "$app_dir/Contents/Resources/AgentIcons"
cp "$bin_dir/CCUsageMenu" "$app_dir/Contents/MacOS/CCUsageMenu"
cp "$root_dir/Resources/Info.plist" "$app_dir/Contents/Info.plist"
cp "$root_dir/.build/AppIconAssets/Assets.car" "$app_dir/Contents/Resources/Assets.car"
cp "$root_dir/.build/AppIconAssets/AppIcon.icns" "$app_dir/Contents/Resources/AppIcon.icns"
cp "$root_dir/Resources/AgentIcons/claude.svg" "$app_dir/Contents/Resources/AgentIcons/claude.svg"
cp "$root_dir/Resources/AgentIcons/codex.png" "$app_dir/Contents/Resources/AgentIcons/codex.png"
codesign --force --deep --sign - "$app_dir"

echo "$app_dir"
