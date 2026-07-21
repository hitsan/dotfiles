#!/bin/bash
# Send a message to a Claude Code session running in another zellij tab
# (same or different session), starting `claude` there first if it isn't
# already running.
set -euo pipefail

usage() {
    echo "Usage: zellij-send.sh <session> <tab-name> <message...>" >&2
    exit 1
}

[ "$#" -ge 3 ] || usage
SESSION="$1"
TAB_NAME="$2"
shift 2
MESSAGE="$*"

zx() {
    zellij -s "$SESSION" action "$@"
}

PANES_JSON=$(zx list-panes -t -j 2>&1) || {
    echo "error: $PANES_JSON" >&2
    exit 1
}

CANDIDATES=$(echo "$PANES_JSON" | jq -c --arg name "$TAB_NAME" \
    '[.[] | select(.is_plugin==false and .is_selectable and (.tab_name | contains($name)))]')

TAB_COUNT=$(echo "$CANDIDATES" | jq '[.[].tab_id] | unique | length')
if [ "$TAB_COUNT" -eq 0 ]; then
    echo "error: no tab matching '$TAB_NAME' in session '$SESSION'" >&2
    exit 1
elif [ "$TAB_COUNT" -gt 1 ]; then
    echo "error: ambiguous tab name '$TAB_NAME', candidates:" >&2
    echo "$CANDIDATES" | jq -r '[.[].tab_name] | unique | .[]' >&2
    exit 1
fi

# 同じtab内に複数paneがある場合はフォーカス中のpaneを優先する。
PANE_ID=$(echo "$CANDIDATES" | jq -r 'sort_by(if .is_focused then 0 else 1 end) | .[0].id')

# Claude CodeのTUIはフッターに "manual mode on/off" を常に表示するので、起動確認の目印に使う。
is_claude_running() {
    zx dump-screen -p "$PANE_ID" 2>/dev/null | grep -qE 'manual mode (on|off)'
}

if ! is_claude_running; then
    zx write-chars -p "$PANE_ID" "claude"
    zx write -p "$PANE_ID" 13
    for _ in $(seq 1 20); do
        sleep 0.5
        is_claude_running && break
    done
    is_claude_running || {
        echo "error: failed to start claude in target pane" >&2
        exit 1
    }
    sleep 0.5
fi

zx write-chars -p "$PANE_ID" "$MESSAGE"
sleep 0.2
zx write -p "$PANE_ID" 13
