#!/usr/bin/env bash
set -euo pipefail

CONTAINER_DIR="/var/lib/claude-config-persist"
STATE_DIR="${CONTAINER_DIR}/.claude"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

owner="${_REMOTE_USER:-root}"
if ! id "$owner" >/dev/null 2>&1; then
    owner="root"
fi

install -d -m 0755 "$CONTAINER_DIR"
chown "${owner}:${owner}" "$CONTAINER_DIR"
install -d -m 0700 "$STATE_DIR"
chown "${owner}:${owner}" "$STATE_DIR"
install -d -m 0755 /usr/local/share/claude

install -m 0755 "$SCRIPT_DIR/onCreate.sh" /usr/local/share/claude/onCreate.sh
