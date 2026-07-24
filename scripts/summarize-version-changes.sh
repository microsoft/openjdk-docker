#!/bin/bash
#
# Prints a human-readable summary of the JDK version changes between two
# versions.json states, one line per changed entry:
#
#     vendor major: old -> new
#
# By default it compares the committed versions.json (git HEAD) against the
# current working-tree versions.json. Both refs can be overridden for testing.
#
# Usage:
#   scripts/summarize-version-changes.sh [current_file] [old_git_ref]
#
# Prints nothing (exit 0) when there are no version changes.

set -euo pipefail

CURRENT_FILE="${1:-versions.json}"
OLD_REF="${2:-HEAD}"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required but not installed" >&2
  exit 1
fi

# Load both files into jq: `old` = the previous versions.json (from git), `new`
# = the current one. --slurpfile reads each JSON file into a single-element array,
# so $old[0] / $new[0] are the actual objects.
#
# The filter walks every "vendor -> { major: version }" entry in the new file,
# pairs each with the matching version in the old file, keeps only the ones whose
# version actually changed, and prints one line per change:
#   "  <vendor> <major>: <old> -> <new>"   (old shown as "(new)" for a brand-new major)
jq -rn \
  --slurpfile old <(git show "${OLD_REF}:${CURRENT_FILE}") \
  --slurpfile new "${CURRENT_FILE}" '
    ($old[0]) as $o | ($new[0]) as $n
    | [ $n | to_entries[] as $vendor | $vendor.value | to_entries[] as $major
        | { vendor: $vendor.key, major: $major.key,
            new: $major.value, old: ($o[$vendor.key][$major.key]) } ]
    | map(select(.new != .old))
    | .[] | "  \(.vendor) \(.major): \(.old // "(new)") -> \(.new)"
  '
