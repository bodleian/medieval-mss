#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
TARGET_DIR="$REPO_ROOT/target"
JAR_PATH="$TARGET_DIR/xml-model-validator.jar"
VERSION_FILE="$TARGET_DIR/xml-model-validator.version"

resolve_validator_version() {
  if [ -n "${XML_MODEL_VALIDATOR_VERSION:-}" ]; then
    printf '%s\n' "$XML_MODEL_VALIDATOR_VERSION"
    return
  fi

  latest_url='https://api.github.com/repos/adunning/xml-model-validator/releases/latest'
  latest_tag=$(curl -fsSL "$latest_url" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)
  if [ -z "$latest_tag" ]; then
    echo 'Unable to determine latest xml-model-validator release tag.' >&2
    exit 1
  fi
  printf '%s\n' "$latest_tag"
}

usage() {
  cat <<'EOF'
Usage: processing/validate_xml.sh [--changed] [xml-model-validator args...]

Options:
  --changed  Validate XML files changed in HEAD compared with HEAD^

Without arguments, the script validates the collections directory.
Otherwise it passes arguments through to xml-model-validator unchanged.
EOF
}

mode="default"

case "${1:-}" in
  --changed)
    mode="changed"
    shift
    ;;
  --help|-h)
    usage
    exit 0
    ;;
esac

mkdir -p "$TARGET_DIR"

VALIDATOR_VERSION=$(resolve_validator_version)
VALIDATOR_URL="https://github.com/adunning/xml-model-validator/releases/download/${VALIDATOR_VERSION}/xml-model-validator.jar"

current_version=''
if [ -f "$VERSION_FILE" ]; then
  current_version=$(cat "$VERSION_FILE")
fi

if [ ! -f "$JAR_PATH" ] || [ "$current_version" != "$VALIDATOR_VERSION" ]; then
  curl -fsSL "$VALIDATOR_URL" -o "$JAR_PATH"
  printf '%s\n' "$VALIDATOR_VERSION" > "$VERSION_FILE"
fi

cd "$REPO_ROOT"

if [ "$mode" = "default" ]; then
  if [ "$#" -eq 0 ]; then
    exec java -jar "$JAR_PATH" --directory collections -j 0
  fi
  exec java -jar "$JAR_PATH" "$@"
fi

file_list=$(mktemp -t xml-model-validator.XXXXXX)
trap 'rm -f "$file_list"' EXIT HUP INT TERM

if git rev-parse --verify HEAD^ >/dev/null 2>&1; then
  git diff --name-only --diff-filter=ACMR HEAD^ HEAD -- '*.xml' > "$file_list"
else
  git ls-files '*.xml' > "$file_list"
fi

if [ ! -s "$file_list" ]; then
  echo 'No changed XML files to validate.'
  exit 0
fi

files_from_flag='--files-from'
if ! java -jar "$JAR_PATH" --help 2>&1 | grep -q -- '--files-from'; then
  files_from_flag='--file-list'
fi

exec java -jar "$JAR_PATH" "$files_from_flag" "$file_list" -j 0 "$@"
