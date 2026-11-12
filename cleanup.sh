#!/usr/bin/env bash
# Removes canaries, the dummy keychain item and the temporary Claude profile.
set -u

rm -rf "$HOME/.poc-secrets" "$HOME/.claude-poc" "$HOME/.poc-write-test"
security delete-generic-password -s poc-test >/dev/null 2>&1 && echo "Removed keychain item poc-test"
echo "Cleanup done. The temp profile's login may remain as a separate 'Claude Code' item in Keychain Access."
