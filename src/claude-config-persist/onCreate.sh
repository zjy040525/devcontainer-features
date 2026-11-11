#!/usr/bin/env bash
set -euo pipefail

CLAUDE_STATE_DIR="/var/lib/claude-config-persist/.claude"
CLAUDE_HOME_LINK="$HOME/.claude"
CLAUDE_JSON_STATE="/var/lib/claude-config-persist/.claude.json"
CLAUDE_JSON_HOME_LINK="$HOME/.claude.json"

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo -n "$@"
    else
        "$@"
    fi
}

is_mountpoint() {
    local path="${1%/}"
    if command -v mountpoint >/dev/null 2>&1; then
        mountpoint -q "$path"
    else
        grep -Fq " $path " /proc/self/mountinfo
    fi
}

take_ownership() {
    run_privileged chown -R "$(id -u):$(id -g)" "$1"
}

ensure_state_dir() {
    local dir="$1"
    run_privileged install -d -m 0700 "$dir" \
        && take_ownership "$dir" \
        && run_privileged chmod 0700 "$dir"
}

ensure_home_link() {
    local state="$1"
    local home_link="$2"

    if [ -L "$home_link" ]; then
        if [ "$(readlink "$home_link")" = "$state" ]; then
            return 0
        fi
        rm -f "$home_link"
    elif [ -d "$home_link" ] && [ -d "$state" ]; then
        run_privileged cp -an "$home_link/." "$state/"
        take_ownership "$state"
        rm -rf "$home_link"
    elif [ -f "$home_link" ] && [ ! -d "$state" ]; then
        run_privileged cp -an "$home_link" "$state"
        take_ownership "$state"
        rm -f "$home_link"
    elif [ -e "$home_link" ]; then
        rm -f "$home_link"
    fi

    ln --symbolic --force --no-dereference "$state" "$home_link"
}

if ! ensure_state_dir "$CLAUDE_STATE_DIR"; then
    echo "claude-config-persist: failed to prepare $CLAUDE_STATE_DIR." >&2
    echo "Make sure the host ~/.claude directory exists before the container is created." >&2
    echo "If Docker created it as root, create it on the host or allow passwordless sudo in the container." >&2
    exit 1
fi

if ! is_mountpoint "$CLAUDE_STATE_DIR"; then
    echo "claude-config-persist: $CLAUDE_STATE_DIR is not a mount point." >&2
    echo "The bind mount for the host ~/.claude directory is missing, so configuration would not persist." >&2
    echo "Check the Feature mounts and rebuild the container." >&2
    exit 1
fi

if ! is_mountpoint "$CLAUDE_JSON_STATE"; then
    echo "claude-config-persist: $CLAUDE_JSON_STATE is not a mount point." >&2
    echo "The bind mount for the host ~/.claude.json file is missing, so configuration would not persist." >&2
    echo "Check the Feature mounts and rebuild the container." >&2
    exit 1
fi

if [ ! -f "$CLAUDE_JSON_STATE" ]; then
    echo "claude-config-persist: $CLAUDE_JSON_STATE is not a regular file." >&2
    echo "The host ~/.claude.json must exist as a file before the container is created:" >&2
    echo "    touch \"\$HOME/.claude.json\"" >&2
    exit 1
fi

take_ownership "$CLAUDE_JSON_STATE"

ensure_home_link "$CLAUDE_STATE_DIR" "$CLAUDE_HOME_LINK"
ensure_home_link "$CLAUDE_JSON_STATE" "$CLAUDE_JSON_HOME_LINK"
