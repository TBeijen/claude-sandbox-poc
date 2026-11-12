#!/usr/bin/env bash
# Installs one of the config/settings.<variant>.json files as the temporary profile's settings.
# Usage: ./switch-config.sh sandbox|sandbox-deny|off   (restart Claude afterwards)
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
CONFIG_DIR="$HOME/.claude-poc"
variant=${1:?usage: $0 sandbox|sandbox-deny|off}
src="$HERE/config/settings.$variant.json"

[[ -f $src ]] || { echo "unknown variant: $variant" >&2; exit 1; }
mkdir -p "$CONFIG_DIR"
cp "$src" "$CONFIG_DIR/settings.json"
echo "Active config: $variant -> $CONFIG_DIR/settings.json"
