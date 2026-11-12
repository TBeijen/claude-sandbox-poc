#!/usr/bin/env bash
# Creates canary secrets, a dummy keychain item and the temporary Claude profile.
# Run from a plain terminal, NOT inside nono.
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
SECRETS="$HOME/.poc-secrets"
CONFIG_DIR="$HOME/.claude-poc"

mkdir -p "$SECRETS/.ssh" "$CONFIG_DIR"
echo "CANARY-SSH-KEY-1234"  > "$SECRETS/.ssh/id_test"
echo "CANARY-GH-TOKEN-5678" > "$SECRETS/token"
chmod 600 "$SECRETS/.ssh/id_test" "$SECRETS/token"

if ! security find-generic-password -s poc-test >/dev/null 2>&1; then
  security add-generic-password -s poc-test -a poc -w CANARY-KEYCHAIN-9999
fi

"$HERE/switch-config.sh" sandbox

echo "Setup done. Next: ./start.sh"
