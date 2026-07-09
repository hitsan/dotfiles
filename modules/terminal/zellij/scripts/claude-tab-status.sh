#!/bin/bash
# Rename the zellij tab a Claude Code pane belongs to, so its activity status
# is visible on the tab itself. Supports multiple Claude panes in the same
# tab: each pane's icon is tracked independently and the tab name is always
# re-rendered from every pane's current icon.
#
# Resolves pane_id -> tab_id via `list-panes -t` so the correct tab is
# targeted even when it isn't the currently focused one.

STATE_DIR="/tmp/claude-tab-status"
mkdir -p "$STATE_DIR"

# The four tab states. Named so a glyph change is one edit, not a scatter.
ICON_NEEDS_USER="🔔"  # your turn: permission / input needed
ICON_BUSY="⏳"         # Claude is working
ICON_FAILED="✗"        # a tool call failed
ICON_DONE="✅"         # Claude finished; your turn

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

# Once ✅ (done) is shown, a working event that lands late must not flip it back
# to ⏳ — async hooks finish in whatever order the OS schedules them, so a slow
# PostToolUse can land after Stop. Only a new turn (UserPromptSubmit) leaves DONE.
should_write() {
    local stored_icon="$1" hook_event="$2"
    if [ "$stored_icon" = "$ICON_DONE" ] && [ "$hook_event" != "UserPromptSubmit" ]; then
        return 1
    fi
    return 0
}

# Test hook: sourcing this file with ZELLIJ_TAB_STATUS_TEST set loads the
# functions above (for unit testing) without running the CLI body below.
[ -n "${ZELLIJ_TAB_STATUS_TEST:-}" ] && return 0 2>/dev/null

[ -z "$ZELLIJ_SESSION_NAME" ] && exit 0
PANE_ID="${ZELLIJ_PANE_ID:-}"
[ -z "$PANE_ID" ] && exit 0

INPUT=$(cat)
HOOK_EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // ""' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
[ -z "$HOOK_EVENT" ] && exit 0

PROJECT_NAME=$(basename "$CWD" 2>/dev/null || echo "?")
if [ ${#PROJECT_NAME} -gt 12 ]; then
    PROJECT_NAME="${PROJECT_NAME:0:6}..."
fi

PANES_JSON=$(zellij -s "$ZELLIJ_SESSION_NAME" action list-panes -t -j 2>/dev/null)
TAB_ID=$(echo "$PANES_JSON" | jq -r --arg id "$PANE_ID" '[.[] | select(.is_plugin==false and (.id|tostring)==$id)][0].tab_id // empty')
[ -z "$TAB_ID" ] && exit 0

# Panes that no longer exist (killed/crashed without a SessionEnd hook) get
# pruned from the state file whenever another pane in the same tab fires.
ALIVE_IDS_JSON=$(echo "$PANES_JSON" | jq -c '[.[] | select(.is_plugin==false) | (.id|tostring)]')

STATE_FILE="${STATE_DIR}/${ZELLIJ_SESSION_NAME}-tab-${TAB_ID}.json"
LOCK_FILE="${STATE_FILE}.lock"
[ -f "$STATE_FILE" ] || echo "{}" > "$STATE_FILE"

if [ "$HOOK_EVENT" = "SessionEnd" ]; then
    (
        flock -x 200
        TMP_FILE=$(mktemp)
        jq --arg pane "$PANE_ID" 'del(.[$pane])' "$STATE_FILE" > "$TMP_FILE" 2>/dev/null && mv "$TMP_FILE" "$STATE_FILE"
        render_tab
    ) 200>"$LOCK_FILE"
    exit 0
fi

case "$HOOK_EVENT" in
    UserPromptSubmit|PreToolUse|PostToolUse|SubagentStop) ICON="$ICON_BUSY" ;;
    PostToolUseFailure) ICON="$ICON_FAILED" ;;
    # matcher (settings.json) already filters this to user-input-needed types.
    Notification)       ICON="$ICON_NEEDS_USER" ;;
    PermissionRequest)  ICON="$ICON_NEEDS_USER" ;;
    Stop)               ICON="$ICON_DONE" ;;
    *) exit 0 ;;
esac

(
    flock -x 200
    STORED_ICON=$(jq -r --arg p "$PANE_ID" '.[$p].icon // ""' "$STATE_FILE" 2>/dev/null)
    if should_write "$STORED_ICON" "$HOOK_EVENT"; then
        TMP_FILE=$(mktemp)
        jq --argjson alive "$ALIVE_IDS_JSON" --arg pane "$PANE_ID" --arg icon "$ICON" --arg project "$PROJECT_NAME" \
            'with_entries(select(.key as $k | ($alive | index($k)) != null)) | .[$pane] = {icon: $icon, project: $project}' \
            "$STATE_FILE" > "$TMP_FILE" 2>/dev/null \
            && mv "$TMP_FILE" "$STATE_FILE"
        render_tab
    fi
) 200>"$LOCK_FILE"
