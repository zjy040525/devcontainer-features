#!/usr/bin/env bash
set -euo pipefail

CC_SWITCH_STATE_DIR="/var/lib/cc-switch-cli/.cc-switch"
CC_SWITCH_HOME_LINK="$HOME/.cc-switch"

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

if ! ensure_state_dir "$CC_SWITCH_STATE_DIR"; then
    echo "cc-switch-cli: failed to prepare $CC_SWITCH_STATE_DIR." >&2
    echo "Make sure the host ~/.cc-switch directory exists before the container is created." >&2
    echo "If Docker created it as root, create it on the host or allow passwordless sudo in the container." >&2
    exit 1
fi

if ! is_mountpoint "$CC_SWITCH_STATE_DIR"; then
    echo "cc-switch-cli: $CC_SWITCH_STATE_DIR is not a mount point." >&2
    echo "The bind mount for the host ~/.cc-switch directory is missing, so configuration would not persist." >&2
    echo "Check the Feature mounts and rebuild the container." >&2
    exit 1
fi

# cc-switch rejects a symlinked config directory. The wrapper resolves this
# link to its absolute target and passes it via CC_SWITCH_CONFIG_DIR.
if [ -L "$CC_SWITCH_HOME_LINK" ]; then
    if [ "$(readlink "$CC_SWITCH_HOME_LINK")" = "$CC_SWITCH_STATE_DIR" ]; then
        exit 0
    fi
    rm -f "$CC_SWITCH_HOME_LINK"
elif [ -d "$CC_SWITCH_HOME_LINK" ]; then
    run_privileged cp -an "$CC_SWITCH_HOME_LINK/." "$CC_SWITCH_STATE_DIR/"
    take_ownership "$CC_SWITCH_STATE_DIR"
    rm -rf "$CC_SWITCH_HOME_LINK"
elif [ -e "$CC_SWITCH_HOME_LINK" ]; then
    rm -f "$CC_SWITCH_HOME_LINK"
fi

ln --symbolic --force --no-dereference "$CC_SWITCH_STATE_DIR" "$CC_SWITCH_HOME_LINK"
