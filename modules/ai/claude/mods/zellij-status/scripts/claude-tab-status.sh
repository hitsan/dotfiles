#!/bin/bash
# Usage: claude-tab-status.sh <icon | ->
# Names this pane's zellij tab after the icon of every Claude pane in it plus the
# project ($PWD); "-" removes this pane. Panes share one state file per tab, so the
# write is locked: separate Claude processes update it.
[ -n "$ZELLIJ_SESSION_NAME" ] && [ -n "$ZELLIJ_PANE_ID" ] || exit 0
z() { zellij -s "$ZELLIJ_SESSION_NAME" action "$@" 2>/dev/null; }

project=$(basename "$PWD")
[ ${#project} -gt 12 ] && project="${project:0:6}..."

panes=$(z list-panes -t -j | jq -c '[.[] | select(.is_plugin == false)]')
tab=$(jq -r --arg p "$ZELLIJ_PANE_ID" '.[] | select((.id | tostring) == $p) | .tab_id' <<< "$panes")
[ -n "$tab" ] || exit 0

dir="${CLAUDE_TAB_STATUS_DIR:-/tmp/claude-tab-status}"
mkdir -p "$dir"
state="$dir/$ZELLIJ_SESSION_NAME-tab-$tab.json"
[ -f "$state" ] || echo '{}' > "$state"

(
  flock -x 200
  jq --argjson alive "$(jq '[.[].id | tostring]' <<< "$panes")" --arg p "$ZELLIJ_PANE_ID" \
    --arg icon "$1" --arg project "$project" '
      with_entries(select(.key as $k | $alive | index($k)))
      | if $icon == "-" then del(.[$p]) else .[$p] = {icon: $icon, project: $project} end
    ' "$state" > "$state.tmp" && mv "$state.tmp" "$state"
  name=$(jq -r --arg project "$project" '
    to_entries | sort_by(.key | tonumber)
    | if length == 0 then $project else "\(map(.value.icon) | join("|")) \(.[0].value.project)" end
  ' "$state")
  z rename-tab -t "$tab" "$name"
) 200> "$state.lock"
