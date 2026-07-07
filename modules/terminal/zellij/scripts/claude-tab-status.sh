#!/bin/bash
# Rename the zellij tab a Claude Code pane belongs to, so its activity status
# is visible on the tab itself. Supports multiple Claude panes in the same
# tab: each pane's icon is tracked independently and the tab name is always
# re-rendered from every pane's current icon, so only the changed slot's
# glyph actually differs between renders.
#
# Resolves pane_id -> tab_id via `list-panes -t` so the correct tab is
# targeted even when it isn't the currently focused one.

STATE_DIR="/tmp/claude-tab-status"
mkdir -p "$STATE_DIR"

# The four tab states. Named so a glyph change is one edit, not a scatter.
ICON_NEEDS_USER="🔔"  # waiting on the user (permission / input)
ICON_BUSY="⏳"         # Claude is working
ICON_FAILED="✗"        # a tool call failed
ICON_DONE="✅"         # Claude finished; user's turn

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

# There is no hook event for "permission granted, tool execution resumed" —
# once a permission prompt sets 🔔, the next event is PostToolUse at
# completion, so a long-running approved tool leaves 🔔 shown the whole
# time. This worker (spawned detached, see bottom of file) polls the
# pane's own screen content for the permission-dialog text and switches to
# a generic busy icon as soon as the dialog is gone (i.e. the user
# answered it), instead of guessing on a blind timer. It bails out
# whenever another event has already updated this pane's entry (checked
# via the ts token, so a newer prompt or completion is never clobbered).
if [ "${1:-}" = "__watch" ]; then
    shift
    # Positional args must match the spawn site at the bottom of this file.
    PANE_ID="$1" STATE_FILE="$2" ORIG_TS="$3" LOCK_FILE="$4" ZELLIJ_SESSION_NAME="$5" TAB_ID="$6"
    POLL_INTERVAL_SEC="${WATCH_POLL_INTERVAL_SEC:-1}"
    MAX_POLLS="${WATCH_MAX_POLLS:-60}"
    DUMP_FILE=$(mktemp)
    i=0
    while [ "$i" -lt "$MAX_POLLS" ]; do
        sleep "$POLL_INTERVAL_SEC"
        CURRENT_TS=$(jq -r --arg p "$PANE_ID" '.[$p].ts // empty' "$STATE_FILE" 2>/dev/null)
        [ "$CURRENT_TS" = "$ORIG_TS" ] || break
        if ! zellij -s "$ZELLIJ_SESSION_NAME" action dump-screen -p "$PANE_ID" --path "$DUMP_FILE" 2>/dev/null; then
            # Don't treat a dump failure as the dialog being gone; skip this round.
            i=$((i + 1))
            continue
        fi
        # '.' matches the apostrophe variants in "don't ask again".
        if ! grep -qE "Do you want to|No, and tell Claude|don.t ask again" "$DUMP_FILE" 2>/dev/null; then
            (
                flock -x 200
                CURRENT_TS=$(jq -r --arg p "$PANE_ID" '.[$p].ts // empty' "$STATE_FILE" 2>/dev/null)
                if [ "$CURRENT_TS" = "$ORIG_TS" ]; then
                    TMP_FILE=$(mktemp)
                    jq --arg pane "$PANE_ID" --arg icon "$ICON_BUSY" '.[$pane].icon = $icon' "$STATE_FILE" > "$TMP_FILE" 2>/dev/null && mv "$TMP_FILE" "$STATE_FILE"
                    render_tab
                fi
            ) 200>"$LOCK_FILE"
            break
        fi
        i=$((i + 1))
    done
    rm -f "$DUMP_FILE"
    exit 0
fi

[ -z "$ZELLIJ_SESSION_NAME" ] && exit 0
PANE_ID="${ZELLIJ_PANE_ID:-}"
[ -z "$PANE_ID" ] && exit 0

# Capture the event time before the slow list-panes call so it tracks hook
# dispatch order. Hooks run async as separate racing processes, so the write
# below uses this as a token: an older event never clobbers a newer one.
TS=$(date +%s%N)

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
WATCH_PID_FILE="${STATE_DIR}/${ZELLIJ_SESSION_NAME}-watch-${PANE_ID}.pid"
[ -f "$STATE_FILE" ] || echo "{}" > "$STATE_FILE"

if [ "$HOOK_EVENT" = "SessionEnd" ]; then
    (
        flock -x 200
        TMP_FILE=$(mktemp)
        jq --arg pane "$PANE_ID" 'del(.[$pane])' "$STATE_FILE" > "$TMP_FILE" 2>/dev/null && mv "$TMP_FILE" "$STATE_FILE"
        render_tab
    ) 200>"$LOCK_FILE"
    rm -f "$WATCH_PID_FILE"
    exit 0
fi

case "$HOOK_EVENT" in
    UserPromptSubmit|PreToolUse|PostToolUse|SubagentStop) ICON="$ICON_BUSY" ;;
    PostToolUseFailure) ICON="$ICON_FAILED" ;;
    Notification)
        NOTIF_TYPE=$(echo "$INPUT" | jq -r '.notification_type // ""' 2>/dev/null)
        case "$NOTIF_TYPE" in
            permission_prompt|elicitation_dialog|agent_needs_input) ICON="$ICON_NEEDS_USER" ;;
            *) exit 0 ;;
        esac
        ;;
    PermissionRequest)  ICON="$ICON_NEEDS_USER" ;;
    Stop)               ICON="$ICON_DONE" ;;
    *) exit 0 ;;
esac

(
    flock -x 200
    # Skip if a newer event already wrote this pane (async hooks can race).
    STORED_TS=$(jq -r --arg p "$PANE_ID" '.[$p].ts // "0"' "$STATE_FILE" 2>/dev/null)
    case "$STORED_TS" in ''|*[!0-9]*) STORED_TS=0 ;; esac
    # Stop marks the turn's final state. Its TS is taken at dispatch time, so
    # a racing PostToolUse for the same turn can still finish writing first
    # and leave a stale busy icon behind. Stop always wins here, and bumps
    # its recorded ts past whatever is stored so later stragglers from the
    # same turn (necessarily older, smaller TS) don't clobber it back.
    if [ "$ICON" = "$ICON_DONE" ]; then
        EFFECTIVE_TS=$TS
        [ "$STORED_TS" -ge "$EFFECTIVE_TS" ] && EFFECTIVE_TS=$((STORED_TS + 1))
        WRITE=1
    elif [ "$STORED_TS" -le "$TS" ]; then
        EFFECTIVE_TS=$TS
        WRITE=1
    else
        WRITE=0
    fi
    if [ "$WRITE" = "1" ]; then
        TMP_FILE=$(mktemp)
        jq --argjson alive "$ALIVE_IDS_JSON" --arg pane "$PANE_ID" --arg icon "$ICON" --arg project "$PROJECT_NAME" --arg ts "$EFFECTIVE_TS" \
            'with_entries(select(.key as $k | ($alive | index($k)) != null)) | .[$pane] = {icon: $icon, project: $project, ts: $ts}' \
            "$STATE_FILE" > "$TMP_FILE" 2>/dev/null \
            && mv "$TMP_FILE" "$STATE_FILE"
        render_tab
    fi
) 200>"$LOCK_FILE"

if [ "$ICON" = "$ICON_NEEDS_USER" ]; then
    # A prior needs-user event may still have its watcher running; kill it
    # before starting a new one so only one watcher per pane polls at a time.
    OLD_PID=$(cat "$WATCH_PID_FILE" 2>/dev/null)
    [ -n "$OLD_PID" ] && kill "$OLD_PID" 2>/dev/null
    # Arg order must match the __watch handler at the top of this file.
    setsid "$0" __watch "$PANE_ID" "$STATE_FILE" "$TS" "$LOCK_FILE" "$ZELLIJ_SESSION_NAME" "$TAB_ID" \
        </dev/null >/dev/null 2>&1 &
    echo "$!" > "$WATCH_PID_FILE"
    disown
fi
