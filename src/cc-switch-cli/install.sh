#!/usr/bin/env bash
set -euo pipefail

CONTAINER_DIR="/var/lib/cc-switch-cli"
STATE_DIR="${CONTAINER_DIR}/.cc-switch"
CC_SWITCH_BIN_DIR="/usr/local/lib/cc-switch-cli"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CC_SWITCH_INSTALL_URL="https://github.com/SaladDay/cc-switch-cli/releases/latest/download/install.sh"

owner="${_REMOTE_USER:-root}"
if ! id "$owner" >/dev/null 2>&1; then
    owner="root"
fi

install -d -m 0755 "$CONTAINER_DIR"
chown "${owner}:${owner}" "$CONTAINER_DIR"
install -d -m 0700 "$STATE_DIR"
chown "${owner}:${owner}" "$STATE_DIR"
install -d -m 0755 /usr/local/share/cc-switch-cli
install -d -m 0755 "$CC_SWITCH_BIN_DIR"

install -m 0755 "$SCRIPT_DIR/onCreate.sh" /usr/local/share/cc-switch-cli/onCreate.sh

if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$CC_SWITCH_INSTALL_URL" \
        | CC_SWITCH_INSTALL_DIR="$CC_SWITCH_BIN_DIR" CC_SWITCH_FORCE=1 bash
elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$CC_SWITCH_INSTALL_URL" \
        | CC_SWITCH_INSTALL_DIR="$CC_SWITCH_BIN_DIR" CC_SWITCH_FORCE=1 bash
else
    echo "cc-switch-cli: curl or wget is required to install cc-switch." >&2
    exit 1
fi

install -m 0755 "$SCRIPT_DIR/wrapper.sh" /usr/local/bin/cc-switch
"$CC_SWITCH_BIN_DIR/cc-switch" --version >/dev/null
