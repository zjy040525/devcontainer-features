#!/usr/bin/env bash
# shellcheck disable=SC2317  # functions are invoked from trap handlers
set -euo pipefail

CC_SWITCH_BIN="/usr/local/lib/cc-switch-cli/cc-switch"
CC_SWITCH_HOME_DIR="$HOME/.cc-switch"
CLAUDE_JSON_HOME_LINK="$HOME/.claude.json"

status=0
claude_json_target=""

resolve_link() {
    local link="$1"
    local target raw dir base

    if target="$(readlink -f "$link" 2>/dev/null)"; then
        printf '%s\n' "$target"
        return 0
    fi

    raw="$(readlink "$link")" || return 1
    case "$raw" in
        /*) target="$raw" ;;
        *) target="$(cd "$(dirname "$link")" && pwd -P)/$raw" ;;
    esac

    dir="$(dirname "$target")"
    base="$(basename "$target")"
    if [ -d "$dir" ]; then
        printf '%s/%s\n' "$(cd "$dir" && pwd -P)" "$base"
    else
        printf '%s\n' "$target"
    fi
}

# cc-switch rejects a symlinked config directory. Pass it the resolved target
# so a ~/.cc-switch (or CC_SWITCH_CONFIG_DIR) symlink keeps working.
if [ -n "${CC_SWITCH_CONFIG_DIR:-}" ] && [ -L "$CC_SWITCH_CONFIG_DIR" ]; then
    if resolved="$(resolve_link "$CC_SWITCH_CONFIG_DIR")"; then
        CC_SWITCH_CONFIG_DIR="$resolved"
        export CC_SWITCH_CONFIG_DIR
    fi
elif [ -z "${CC_SWITCH_CONFIG_DIR:-}" ] && [ -L "$CC_SWITCH_HOME_DIR" ]; then
    if resolved="$(resolve_link "$CC_SWITCH_HOME_DIR")"; then
        CC_SWITCH_CONFIG_DIR="$resolved"
        export CC_SWITCH_CONFIG_DIR
    fi
fi

if [ -L "$CLAUDE_JSON_HOME_LINK" ]; then
    claude_json_target="$(resolve_link "$CLAUDE_JSON_HOME_LINK" 2>/dev/null || true)"
fi

# cc-switch rewrites ~/.claude.json with a temp file followed by rename(2).
# A rename replaces a symlink instead of writing through it, so copy the new
# content back to the resolved target and recreate the link.
restore_claude_json_link() {
    if [ -n "$claude_json_target" ] \
        && [ ! -d "$claude_json_target" ] \
        && [ -f "$CLAUDE_JSON_HOME_LINK" ] \
        && [ ! -L "$CLAUDE_JSON_HOME_LINK" ]; then
        if cp -a "$CLAUDE_JSON_HOME_LINK" "$claude_json_target"; then
            rm -f "$CLAUDE_JSON_HOME_LINK" || true
            ln --symbolic "$claude_json_target" "$CLAUDE_JSON_HOME_LINK" || true
        fi
    fi
}

finish() {
    restore_claude_json_link
    exit "$status"
}

trap finish EXIT
trap 'status=130; exit 130' INT
trap 'status=143; exit 143' TERM
trap 'status=129; exit 129' HUP

"$CC_SWITCH_BIN" "$@" || status=$?
exit "$status"
