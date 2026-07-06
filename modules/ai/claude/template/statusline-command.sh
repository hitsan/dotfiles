#!/bin/sh

input=$(cat)

dir=$(printf '%s' "$input" | jq -r '.workspace.current_dir')
model=$(printf '%s' "$input" | jq -r '.model.display_name')
ctx=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
rl5=$(printf '%s' "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')

branch=""
if git --no-optional-locks -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git --no-optional-locks -C "$dir" branch --show-current 2>/dev/null)
fi

YELLOW='\033[33m'
CYAN='\033[36m'
GREEN='\033[32m'
RED='\033[31m'
DIM='\033[2m'
RESET='\033[0m'

# Color a percentage: green <50, yellow <80, red otherwise.
pct_color() {
  n=${1%%.*}
  case "$n" in ''|*[!0-9]*) n=0 ;; esac
  if [ "$n" -lt 50 ]; then printf '%s' "$GREEN"
  elif [ "$n" -lt 80 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$RED"
  fi
}

out="${CYAN}${model}${RESET}"
[ -n "$branch" ] && out="${YELLOW} ${branch}${RESET} ${out}"

if [ -n "$ctx" ]; then
  ci=${ctx%%.*}
  out="${out} ${DIM}·${RESET} $(pct_color "$ci")ctx ${ci}%${RESET}"
fi

if [ -n "$rl5" ]; then
  r5=${rl5%%.*}
  out="${out} ${DIM}·${RESET} $(pct_color "$r5")5h ${r5}%${RESET}"
fi

printf '%b\n' "$out"
