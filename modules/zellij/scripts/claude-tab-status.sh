#!/bin/bash
# Rename the zellij tab that a Claude Code pane belongs to, so its activity
# status is visible on the tab itself (not just the aggregated zjstatus bar).
# Resolves pane_id -> tab_id via `list-panes -t` so the correct tab is
# targeted even when it isn't the currently focused one.

[ -z "$ZELLIJ_SESSION_NAME" ] && exit 0
PANE_ID="${ZELLIJ_PANE_ID:-}"
[ -z "$PANE_ID" ] && exit 0

INPUT=$(cat)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)

case "$HOOK_EVENT" in
    PreToolUse|UserPromptSubmit)    ICON="⏳" ;;
    Notification|PermissionRequest) ICON="🔴" ;;
    Stop)                           ICON="✅" ;;
    *) exit 0 ;;
esac

PROJECT_NAME=$(basename "$CWD" 2>/dev/null || echo "?")
if [ ${#PROJECT_NAME} -gt 12 ]; then
    PROJECT_NAME="${PROJECT_NAME:0:6}..."
fi

TAB_ID=$(zellij -s "$ZELLIJ_SESSION_NAME" action list-panes -t -j 2>/dev/null \
    | jq -r --arg id "$PANE_ID" '[.[] | select(.is_plugin==false and (.id|tostring)==$id)][0].tab_id // empty')
[ -z "$TAB_ID" ] && exit 0

zellij -s "$ZELLIJ_SESSION_NAME" action rename-tab -t "$TAB_ID" "$ICON $PROJECT_NAME" 2>/dev/null || true
