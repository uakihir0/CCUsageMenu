#!/bin/zsh

set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
output_path="${1:-$root_dir/docs/ccusage-menu.png}"

CLANG_MODULE_CACHE_PATH="$root_dir/.build/ModuleCache" \
SWIFTPM_MODULECACHE_OVERRIDE="$root_dir/.build/ModuleCache" \
    swift build \
        --package-path "$root_dir" \
        --configuration release

bin_dir="$(CLANG_MODULE_CACHE_PATH="$root_dir/.build/ModuleCache" \
    SWIFTPM_MODULECACHE_OVERRIDE="$root_dir/.build/ModuleCache" \
    swift build \
        --package-path "$root_dir" \
        --configuration release \
        --show-bin-path)"

"$bin_dir/CCUsageMenu" --generate-screenshot "$output_path"
echo "$output_path"
