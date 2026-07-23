#!/bin/bash
#
# Updates versions.json with the latest published patch versions:
#   * msopenjdk (Microsoft Build of OpenJDK) - scraped from the official
#     download page.
#   * temurin (Eclipse Temurin) - queried from the Adoptium API.
#
# The set of major versions to track is driven by the keys already present in
# versions.json, so adding/removing a major only requires editing the JSON file.
#
# Usage: scripts/update-versions.sh [versions.json]

set -euo pipefail

VERSIONS_FILE="${1:-versions.json}"
PAGE_URL="${JDK_DOWNLOAD_URL:-https://learn.microsoft.com/en-us/java/openjdk/download}"
ADOPTIUM_API="${ADOPTIUM_API:-https://api.adoptium.net/v3/assets/latest}"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required but not installed" >&2
  exit 1
fi

if [[ ! -f "$VERSIONS_FILE" ]]; then
  echo "error: versions file not found: $VERSIONS_FILE" >&2
  exit 1
fi

updated="$(cat "$VERSIONS_FILE")"

set_version() {
  # set_version <vendor> <major> <latest>
  local vendor="$1" major="$2" latest="$3" current
  current="$(printf '%s' "$updated" | jq -r --arg d "$vendor" --arg m "$major" '.[$d][$m]')"
  if [[ "$latest" != "$current" ]]; then
    echo "${vendor} ${major}: ${current} -> ${latest}"
  fi
  updated="$(printf '%s' "$updated" \
    | jq --arg d "$vendor" --arg m "$major" --arg v "$latest" '.[$d][$m] = $v')"
}

# --- msopenjdk: scrape the Microsoft download page -------------------------
html="$(curl -fsSL "$PAGE_URL")"

for major in $(jq -r '.msopenjdk | keys[]' "$VERSIONS_FILE"); do
  # Every major publishes a linux-x64 tarball; use it as the canonical artifact
  # to discover the latest patch version (e.g. microsoft-jdk-25.0.3-linux-x64.tar.gz).
  latest="$(printf '%s' "$html" \
    | grep -oiE "microsoft-jdk-${major}(\.[0-9]+)+-linux-x64\.tar\.gz" \
    | grep -oiE "${major}(\.[0-9]+)+" \
    | sort -V \
    | tail -n1)"

  if [[ -z "$latest" ]]; then
    echo "warning: no download link found for msopenjdk major ${major}, keeping current value" >&2
    continue
  fi

  set_version "msopenjdk" "$major" "$latest"
done

# --- temurin: query the Adoptium API ---------------------------------------
for major in $(jq -r '.temurin | keys[]' "$VERSIONS_FILE"); do
  openjdk_version="$(curl -fsSL \
    "${ADOPTIUM_API}/${major}/hotspot?os=linux&architecture=x64&image_type=jdk" \
    | jq -r '.[0].version.openjdk_version // empty')"

  if [[ -z "$openjdk_version" ]]; then
    echo "warning: no Adoptium release found for temurin major ${major}, keeping current value" >&2
    continue
  fi

  # openjdk_version looks like "1.8.0_472-b08"; strip the build suffix to match
  # the $JAVA_VERSION string reported by the image (e.g. "1.8.0_472").
  latest="${openjdk_version%%-*}"
  latest="${latest%%+*}"

  set_version "temurin" "$major" "$latest"
done

printf '%s\n' "$updated" > "$VERSIONS_FILE"

