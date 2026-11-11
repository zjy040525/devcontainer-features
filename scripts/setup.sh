#!/bin/bash
set -euo pipefail

FEATURE_NAME="claude-config-persist"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_DIRECTORY="$PROJECT_ROOT/src/$FEATURE_NAME"
TARGET_DIRECTORY="$PROJECT_ROOT/.devcontainer/$FEATURE_NAME"

echo "Cleaning up old directory..."
rm -rf "$TARGET_DIRECTORY"

echo "Creating target directory..."
mkdir -p "$TARGET_DIRECTORY"

echo "Creating hard links..."
# 开启 nullglob 避免源目录为空时通配符无法匹配抛错
shopt -s nullglob

for filepath in "$SOURCE_DIRECTORY"/*; do
  filename="$(basename "$filepath")"
  
  # 忽略以点开头的文件/隐藏文件
  if [[ "$filename" != .* ]]; then
    ln "$filepath" "$TARGET_DIRECTORY/$filename"
  fi
done

echo "Done! Hard links are ready. You can now 'Reopen in Container' in VS Code."
