#!/usr/bin/env bash
# Checks this repository's internal consistency. Run it before opening a pull
# request; CI runs the same script.
#
#   bash dev/check-repo.sh          report problems
#   bash dev/check-repo.sh --fix    refresh the copies under template/
#
# The template ships a committed copy of standards.md and of the two hooks, so
# that agents other than Claude Code can read the standards and so a fresh
# checkout works offline. Those copies have to match the originals, and
# nothing but this check enforces it.

set -uo pipefail
cd "$(dirname "$0")/.."

fix=0
[ "${1:-}" = "--fix" ] && fix=1
status=0

copies=(
  "standards.md:template/dev/standards.md"
  "hooks/load-standards.sh:template/dev/hooks/load-standards.sh"
  "hooks/lint-changed.sh:template/dev/hooks/lint-changed.sh"
)

for pair in "${copies[@]}"; do
  source_file="${pair%%:*}"
  copy="${pair##*:}"
  if ! diff -q "$source_file" "$copy" > /dev/null 2>&1; then
    if [ "$fix" -eq 1 ]; then
      cp "$source_file" "$copy"
      echo "fixed:  $copy now matches $source_file"
    else
      echo "ERROR:  $copy differs from $source_file. Run 'bash dev/check-repo.sh --fix'."
      status=1
    fi
  fi
done

while IFS= read -r script; do
  if ! bash -n "$script" 2> /dev/null; then
    echo "ERROR:  $script is not valid bash:"
    bash -n "$script"
    status=1
  fi
done < <(find . -name '*.sh' -not -path './.git/*')

if command -v python3 > /dev/null 2>&1; then
  while IFS= read -r workflow; do
    python3 -c "
import sys
try:
    import yaml
except ImportError:
    sys.exit(0)
yaml.safe_load(open(sys.argv[1]))
" "$workflow" || { echo "ERROR:  $workflow is not valid YAML."; status=1; }
  done < <(find .github/workflows -name '*.yaml' 2> /dev/null)
fi

if [ "$status" -eq 0 ]; then
  echo "Repository checks passed."
fi
exit "$status"
