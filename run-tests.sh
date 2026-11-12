#!/usr/bin/env bash
# Probes what the current execution context can reach. Run the same script via:
#   1. a plain terminal (baseline)
#   2. `! ./run-tests.sh` inside Claude (user bash mode)
#   3. asking Claude to run ./run-tests.sh with its Bash tool
# and compare. Only canary values are ever printed; real paths report counts/names only.
set -u

HERE=$(cd "$(dirname "$0")" && pwd)
SECRETS="$HOME/.poc-secrets"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude-poc}"

report() { printf '%-4s %-9s %-44s %s\n' "$1" "$2" "$3" "${4:-}"; }

first_line() { head -n1 <<<"$1" | cut -c1-70; }

# id, description, canary, command...
probe_read() {
  local id=$1 desc=$2 canary=$3; shift 3
  local out
  out=$("$@" 2>&1)
  if [[ $out == *"$canary"* ]]; then
    report "$id" EXPOSED "$desc"
  else
    report "$id" BLOCKED "$desc" "$(first_line "$out")"
  fi
}

# id, description, path
probe_write() {
  local id=$1 desc=$2 path=$3
  local out
  if out=$(touch "$path" 2>&1); then
    rm -f "$path"
    report "$id" WRITABLE "$desc"
  else
    report "$id" BLOCKED "$desc" "$(first_line "$out")"
  fi
}

echo "context: CLAUDE_CONFIG_DIR=${CLAUDE_CONFIG_DIR:-<unset>} SANDBOX_RUNTIME=${SANDBOX_RUNTIME:-<unset>}"
echo "----"

probe_read T1 "cat canary token" CANARY-GH-TOKEN \
  cat "$SECRETS/token"
probe_read T2 "cat ssh-shaped canary key" CANARY-SSH-KEY \
  cat "$SECRETS/.ssh/id_test"
probe_read T3 "python3 child process read" CANARY-GH-TOKEN \
  python3 -I -c "import sys; print(open(sys.argv[1]).read())" "$SECRETS/token"
probe_read T4 "nested bash -c read" CANARY-SSH-KEY \
  bash -c 'cat "$1"' _ "$SECRETS/.ssh/id_test"
probe_read T5 "keychain item via security(1)" CANARY-KEYCHAIN \
  security find-generic-password -s poc-test -w

probe_write T6 "write outside cwd (\$HOME)" "$HOME/.poc-write-test"
probe_write T7 "write inside cwd (expected allowed)" "$HERE/.poc-write-test"
probe_write T8 "write into Claude profile dir" "$CONFIG_DIR/.poc-write-test"

# Policy tampering: can the contained process create project settings?
if [[ -e $HERE/.claude/settings.json ]]; then
  report T9 SKIPPED "write project .claude/settings.json" "file already exists"
elif out=$( { mkdir -p "$HERE/.claude" && echo '{}' > "$HERE/.claude/settings.json"; } 2>&1 ); then
  rm -f "$HERE/.claude/settings.json"; rmdir "$HERE/.claude" 2>/dev/null
  report T9 WRITABLE "write project .claude/settings.json"
else
  rmdir "$HERE/.claude" 2>/dev/null
  report T9 BLOCKED "write project .claude/settings.json" "$(first_line "$out")"
fi

if code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 https://example.com 2>&1) && [[ $code != 000 ]]; then
  report T10 REACHABLE "network: https://example.com" "HTTP $code"
else
  report T10 BLOCKED "network: https://example.com" "$code"
fi

# Real paths not in denyRead: report counts only, never contents.
if n=$(ls -A "$HOME/.ssh" 2>/dev/null | wc -l | tr -d ' ') && [[ -r $HOME/.ssh ]]; then
  report T11 READABLE "list real ~/.ssh (default-allow check)" "$n entries"
else
  report T11 BLOCKED "list real ~/.ssh (default-allow check)"
fi

names=$(env | cut -d= -f1 | grep -Ei 'token|secret|key|passw' | tr '\n' ' ')
report T12 INFO "secret-looking env var names" "${names:-none}"
