#!/usr/bin/env bash
# PostToolUse hook for Claude Code: checks a Python file right after Claude
# edits it and passes the findings back to Claude. It reports only and never
# rewrites the file: auto-formatting on every edit would bury the real change
# in formatting noise.
#
# Packages don't copy this file. dev/hooks/load-standards.sh downloads it at
# each session start, and the package's dev/hooks/lint-changed.sh stub runs the
# downloaded copy.
#
# Source: https://github.com/campbio/py-dev-standards
#
# Claude Code sends the hook payload as JSON on stdin. Plain stdout from a
# PostToolUse hook only reaches the debug log, so the findings are returned as
# JSON in hookSpecificOutput.additionalContext, which Claude does see. Always
# exits 0: a lint is information, not a reason to fail the edit.

set -uo pipefail

command -v python3 > /dev/null 2>&1 || exit 0

payload="$(cat)"
file="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("file_path", ""))
except Exception:
    print("")')"

[ -n "$file" ] && [ -f "$file" ] || exit 0
case "$file" in
  *.py) ;;
  *) exit 0 ;;
esac

# Prefer the project's own environment so the package's ruff and mypy settings
# and plugin versions are the ones that run.
tool() {
  if [ -x ".venv/bin/$1" ]; then
    echo ".venv/bin/$1"
  elif command -v "$1" > /dev/null 2>&1; then
    echo "$1"
  fi
}
ruff="$(tool ruff)"
mypy="$(tool mypy)"

findings=""

if [ -n "$ruff" ]; then
  # --force-exclude makes ruff honour the project's exclude settings even
  # though the file is named explicitly.
  lints="$("$ruff" check --force-exclude --output-format=concise "$file" 2> /dev/null \
    | grep -v '^Found ' | grep -v '^\[\*\]')"
  [ -n "$lints" ] && findings="$findings$lints
"
  if ! "$ruff" format --force-exclude --check "$file" > /dev/null 2>&1; then
    findings="$findings$file: formatting differs from ruff format; run \`make format\`
"
  fi
fi

# mypy only on package source: tests are deliberately checked less strictly,
# and --follow-imports=silent keeps errors from other modules out of the way.
case "$file" in
  src/*)
    if [ -n "$mypy" ]; then
      types="$("$mypy" --follow-imports=silent --no-error-summary \
        --no-pretty --hide-error-context "$file" 2> /dev/null)"
      [ -n "$types" ] && findings="$findings$types
"
    fi
    ;;
esac

[ -n "$findings" ] || exit 0

# At most 25 lines, so a file with an existing backlog can't flood the session.
printf '%s' "$findings" | python3 -c '
import json, os, sys

lines = [ln for ln in sys.stdin.read().splitlines() if ln.strip()]
total = len(lines)
shown = lines[:25]
header = (
    f"{total} issue(s) found in {os.path.basename(sys.argv[1])}. "
    "Fix the ones on lines you changed; leave pre-existing issues elsewhere "
    "in the file for a separate PR."
)
body = "\n".join("  " + ln for ln in shown)
if total > 25:
    body += f"\n  ... and {total - 25} more"
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": header + "\n" + body,
}}))' "$file"
exit 0
