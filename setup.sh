#!/bin/bash
set -eu

# Define feature name and directory paths
FEATURE_NAME="claude-config-persist"
SRC_DIR="src/${FEATURE_NAME}"
TARGET_DIR=".devcontainer/${FEATURE_NAME}"

echo "Cleaning up old directory/symlinks..."
rm -rf "$TARGET_DIR"

echo "Creating target directory..."
mkdir -p "$TARGET_DIR"

echo "Creating hard links..."
# Use cp -l to create hard links for all files in the directory
cp -l "$SRC_DIR"/* "$TARGET_DIR"/

echo "Done! Hard links are ready. You can now 'Reopen in Container' in VS Code."
