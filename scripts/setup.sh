#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 开启 nullglob 避免源目录为空时通配符无法匹配抛错
shopt -s nullglob

for SOURCE_DIRECTORY in "$PROJECT_ROOT"/src/*/; do
  FEATURE_NAME="$(basename "$SOURCE_DIRECTORY")"
  TARGET_DIRECTORY="$PROJECT_ROOT/.devcontainer/$FEATURE_NAME"

  echo "Cleaning up old directory: $TARGET_DIRECTORY"
  rm -rf "$TARGET_DIRECTORY"

  echo "Creating target directory..."
  mkdir -p "$TARGET_DIRECTORY"

  echo "Creating hard links for $FEATURE_NAME..."
  for filepath in "$SOURCE_DIRECTORY"*; do
    filename="$(basename "$filepath")"

    # 忽略以点开头的文件/隐藏文件
    if [[ "$filename" != .* ]]; then
      ln "$filepath" "$TARGET_DIRECTORY/$filename"
    fi
  done
done

echo "Done! Hard links are ready. You can now 'Reopen in Container' in VS Code."
