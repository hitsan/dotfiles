#!/bin/bash
# Rename the zellij tab a Claude Code pane belongs to, so its activity status
# is visible on the tab itself. Supports multiple Claude panes in the same
# tab: each pane's icon is tracked independently and the tab name is always
# re-rendered from every pane's current icon, so only the changed slot's
# glyph actually differs between renders.
#
# Resolves pane_id -> tab_id via `list-panes -t` so the correct tab is
# targeted even when it isn't the currently focused one.

[ -z "$ZELLIJ_SESSION_NAME" ] && exit 0
PANE_ID="${ZELLIJ_PANE_ID:-}"
[ -z "$PANE_ID" ] && exit 0

STATE_DIR="/tmp/claude-tab-status"
mkdir -p "$STATE_DIR"

INPUT=$(cat)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)

[ -z "$HOOK_EVENT" ] && exit 0

PROJECT_NAME=$(basename "$CWD" 2>/dev/null || echo "?")
if [ ${#PROJECT_NAME} -gt 12 ]; then
    PROJECT_NAME="${PROJECT_NAME:0:6}..."
fi

TAB_ID=$(zellij -s "$ZELLIJ_SESSION_NAME" action list-panes -t -j 2>/dev/null \
    | jq -r --arg id "$PANE_ID" '[.[] | select(.is_plugin==false and (.id|tostring)==$id)][0].tab_id // empty')
[ -z "$TAB_ID" ] && exit 0

STATE_FILE="${STATE_DIR}/tab-${TAB_ID}.json"
[ -f "$STATE_FILE" ] || echo "{}" > "$STATE_FILE"

# Re-render the tab name from every pane's current icon in this tab.
render_tab() {
    local composite project
    composite=$(jq -r '[to_entries | sort_by(.key | tonumber)[] | .value.icon] | join("|")' "$STATE_FILE" 2>/dev/null)
    project=$(jq -r '(to_entries | sort_by(.key | tonumber))[0].value.project // empty' "$STATE_FILE" 2>/dev/null)
    if [ -z "$composite" ]; then
        zellij -s "$ZELLIJ_SESSION_NAME" action rename-tab -t "$TAB_ID" "$PROJECT_NAME" 2>/dev/null || true
    else
        zellij -s "$ZELLIJ_SESSION_NAME" action rename-tab -t "$TAB_ID" "${composite} ${project}" 2>/dev/null || true
    fi
}

if [ "$HOOK_EVENT" = "SessionEnd" ]; then
    TMP_FILE=$(mktemp)
    jq --arg pane "$PANE_ID" 'del(.[$pane])' "$STATE_FILE" > "$TMP_FILE" 2>/dev/null && mv "$TMP_FILE" "$STATE_FILE"
    render_tab
    exit 0
fi

case "$HOOK_EVENT" in
    UserPromptSubmit)  ICON="▶" ;;
    PreToolUse)
        case "$TOOL_NAME" in
            Bash)               ICON="⚡" ;;
            Read|Glob|Grep)     ICON="🔍" ;;
            Write|Edit)         ICON="✎" ;;
            WebSearch|WebFetch) ICON="🌐" ;;
            Task)               ICON="🤖" ;;
            *)                  ICON="⏳" ;;
        esac
        ;;
    PostToolUse)        ICON="◐" ;;
    Notification)       ICON="🔔" ;;
    PermissionRequest)  ICON="🔴" ;;
    Stop)               ICON="✅" ;;
    SubagentStop)       ICON="▷" ;;
    *) exit 0 ;;
esac

TMP_FILE=$(mktemp)
jq --arg pane "$PANE_ID" --arg icon "$ICON" --arg project "$PROJECT_NAME" --arg ts "$(date +%s)" \
    '.[$pane] = {icon: $icon, project: $project, ts: ($ts | tonumber)}' "$STATE_FILE" > "$TMP_FILE" 2>/dev/null \
    && mv "$TMP_FILE" "$STATE_FILE"

render_tab
