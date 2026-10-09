#!/bin/bash
# Runs claude-tab-status.sh against a fake `zellij` that serves a pane list and logs renames.
SCRIPT="$(cd "$(dirname "$0")" && pwd)/claude-tab-status.sh"
WORK=$(mktemp -d)
trap 'rm -r "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/myproject"
cat > "$WORK/bin/zellij" <<'EOF'
#!/bin/bash
case "$*" in
  *list-panes*) cat "$FAKE_PANES" ;;
  *rename-tab*) echo "${@: -1}" >> "$FAKE_LOG" ;;
esac
EOF
chmod +x "$WORK/bin/zellij"

export PATH="$WORK/bin:$PATH" FAKE_PANES="$WORK/panes.json" FAKE_LOG="$WORK/log"
export CLAUDE_TAB_STATUS_DIR="$WORK/state" ZELLIJ_SESSION_NAME=s
echo '[{"id":1,"is_plugin":false,"tab_id":0},{"id":2,"is_plugin":false,"tab_id":0}]' > "$FAKE_PANES"

fails=0
status() { (cd "$WORK/myproject" && ZELLIJ_PANE_ID=$1 "$SCRIPT" "$2"); }
expect_last() {
  local got
  got=$(tail -n1 "$FAKE_LOG" 2>/dev/null)
  if [ "$got" = "$2" ]; then echo "ok   $1"; else echo "FAIL $1: got '$got', want '$2'"; fails=$((fails + 1)); fi
}

status 1 "⏳"
expect_last "one pane shows its icon and the project" "⏳ myproject"

status 2 "✅"
expect_last "panes of one tab are joined in pane order" "⏳|✅ myproject"

status 1 -
expect_last "a removed pane drops out of the tab name" "✅ myproject"

echo '[{"id":1,"is_plugin":false,"tab_id":0}]' > "$FAKE_PANES"
status 1 "🔔"
expect_last "a pane that no longer exists is pruned" "🔔 myproject"

status 1 -
expect_last "the last pane leaving restores the plain project name" "myproject"

: > "$FAKE_LOG"
(cd "$WORK/myproject" && ZELLIJ_SESSION_NAME='' ZELLIJ_PANE_ID=1 "$SCRIPT" "⏳")
expect_last "outside zellij nothing is renamed" ""

exit $fails
