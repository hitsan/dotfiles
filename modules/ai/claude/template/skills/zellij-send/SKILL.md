---
name: zellij-send
description: Send a text message to a Claude Code instance running in another zellij tab or session, starting `claude` there first if it isn't already running. Use when the user asks to relay a message, instruction, or question to another Claude Code session — e.g. "別のタブのClaudeに〜と伝えて", "他のセッションのClaudeに聞いて", "send this to the other Claude session".
---

# Zellij Send

## Overview

Delivers a message to a Claude Code instance in a different zellij tab/session via
`~/.config/zellij/scripts/zellij-send.sh`. The script resolves the target pane by
tab name, writes the message into it, and presses Enter. If no Claude Code is
running there yet, it launches `claude` first and waits for it to be ready.

The script never changes which tab/pane is currently focused on screen.

## Workflow

### Step 1: Identify the target

1. List available sessions: `zellij list-sessions -n`
2. For each candidate session, list its tabs:
   `zellij -s <session> action list-tabs`
   (use `$ZELLIJ_SESSION_NAME` for the current session)
3. Match the user's hint (tab name, session name, project name, etc.) against
   the tab names.
   - If exactly one tab matches, proceed without asking.
   - If the hint is ambiguous or missing, use AskUserQuestion to let the user
     pick from the candidate tabs.
4. Never target the tab/pane this conversation is currently running in.

### Step 2: Send the message

```
~/.config/zellij/scripts/zellij-send.sh <session-name> <tab-name> "<message>"
```

- `<tab-name>` matches by substring against tab names.
- If the target tab has multiple panes, the currently focused pane in that tab
  is used.
- If Claude Code isn't running in the target pane yet, the script starts it
  and waits up to ~10s before sending the message.

Check the exit code and stderr:

| stderr contains | meaning | what to do |
|---|---|---|
| `ambiguous tab name ... candidates:` | multiple tabs matched | show candidates to the user, retry with a more specific name |
| `no tab matching` / `session ... not found` | nothing matched | re-list sessions/tabs, confirm target with the user |
| `failed to start claude in target pane` | pane didn't reach a ready state in time | inspect with `zellij -s <session> action dump-screen -p <pane_id>`, report to the user rather than retrying blindly |

### Step 3: Report back

Tell the user which session/tab received the message and what was sent. Do
not poll the target pane waiting for a reply unless the user asks for that —
report success/failure of the send itself and stop.

## Notes

- Startup detection greps the target pane's screen dump for the TUI footer
  text `manual mode (on|off)`, which Claude Code always renders once loaded
  (as of Claude Code v2.1.214). If a future UI change removes that text, the
  script will misreport "failed to start" — verify with `dump-screen` in that
  case rather than assuming the script is broken.
- If the target pane already has unsent text in its prompt, the sent message
  will be appended to it, not sent cleanly.
