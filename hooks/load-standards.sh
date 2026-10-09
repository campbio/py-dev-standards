#!/usr/bin/env bash
# SessionStart hook for Claude Code. It downloads the shared files from the
# py-dev-standards repo into a cache, then prints the development standards so
# Claude Code adds them to the session's context:
#
#   standards.md             the standards, printed below
#   shared/lint-changed.sh   run by the dev/hooks/lint-changed.sh stub
#   shared/standards.mk      the standard targets, included by the Makefile
#
# Copy this file to dev/hooks/load-standards.sh in each package and register it
# in .claude/settings.json (see ADOPTING.md). It rarely changes: the shared
# files update centrally when the maintainer moves the v1 tag.
#
# Source: https://github.com/campbio/py-dev-standards
#
# Environment variables:
#   PY_STANDARDS_REF    tag or branch to use (default v1). To test a branch
#                       for one session:  PY_STANDARDS_REF=<branch> claude
#   PY_STANDARDS_BASE   where to download from (default: this repo on GitHub
#                       at that ref). Forks set this.
#
# If GitHub is unreachable the last downloaded copies are used, and if there
# are none the package's committed dev/standards.md is used. Always exits 0 so
# a network problem never blocks a session.

set -u

ref="${PY_STANDARDS_REF:-v1}"
base="${PY_STANDARDS_BASE:-https://raw.githubusercontent.com/campbio/py-dev-standards/$ref}"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/py-dev-standards/$ref"

mkdir -p "$cache_dir" 2> /dev/null

# fetch <path in repo> <name in cache>: download to a temp file, then move it
# into place, so a failed download never replaces a good cached copy. Returns 0
# only if a fresh copy was downloaded.
fetch() {
  local tmp
  tmp="$(mktemp "$cache_dir/download.XXXXXX" 2> /dev/null)" || return 1
  if curl -fsSL --max-time 10 "$base/$1" -o "$tmp" 2> /dev/null \
     && [ -s "$tmp" ] && mv -f "$tmp" "$cache_dir/$2"; then
    return 0
  fi
  rm -f "$tmp"
  return 1
}

# The three downloads run in parallel, so a slow network costs one timeout,
# not three.
fetch standards.md standards.md & p1=$!
fetch shared/lint-changed.sh lint-changed.sh & p2=$!
fetch shared/standards.mk standards.mk & p3=$!
stale=0
for p in "$p1" "$p2" "$p3"; do
  wait "$p" || stale=1
done

if [ -s "$cache_dir/standards.md" ]; then
  if [ "$stale" -eq 1 ]; then
    echo "NOTE: Some shared development files could not be downloaded, so"
    echo "cached copies are being used and may be out of date. Tell the user."
    echo
  fi
  cat "$cache_dir/standards.md"
elif [ -s dev/standards.md ]; then
  echo "NOTE: The shared development standards could not be downloaded and"
  echo "nothing is cached, so this package's committed dev/standards.md is"
  echo "being used. It may be out of date. Tell the user."
  echo
  cat dev/standards.md
else
  echo "WARNING: The development standards (py-dev-standards) could not be"
  echo "loaded and no cached or committed copy exists. Tell the user before"
  echo "starting any work."
fi
exit 0
