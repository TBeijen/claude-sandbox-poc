#!/usr/bin/env bash
# Starts Claude Code with the temporary profile, from this directory.
# Usage: ./start.sh          plain (Claude's own sandbox only)
#        ./start.sh --nono   wrapped in nono, only this dir + the profile allowed
set -euo pipefail

HERE=$(cd "$(dirname "$0")" && pwd)
CONFIG_DIR="$HOME/.claude-poc"
cd "$HERE"

if [[ ${1:-} == --nono ]]; then
  shift
  # Likely needs extra --allow flags for Claude to start (node/mise installs, keychain for login).
  exec nono run --allow "$HERE" --allow "$CONFIG_DIR" -- env CLAUDE_CONFIG_DIR="$CONFIG_DIR" claude "$@"
fi

exec env CLAUDE_CONFIG_DIR="$CONFIG_DIR" claude "$@"
