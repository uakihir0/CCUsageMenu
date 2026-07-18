#!/bin/zsh

set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
language="${1:-english}"

case "$language" in
    english)
        default_output="$root_dir/docs/ccusage-menu-en.png"
        ;;
    japanese)
        default_output="$root_dir/docs/ccusage-menu.png"
        ;;
    *)
        echo "Usage: $0 [english|japanese] [output-path]" >&2
        exit 1
        ;;
esac

output_path="${2:-$default_output}"

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

"$bin_dir/CCUsageMenu" \
    --generate-screenshot "$output_path" \
    --screenshot-language "$language"
echo "$output_path"
