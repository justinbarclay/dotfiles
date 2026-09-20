#!/usr/bin/env bash
# agy status line: reads the state JSON on stdin, prints one ANSI-coloured line.
# Payload schema: https://antigravity.google/docs/cli/statusline/

IFS='|' read -r state model branch dirty used < <(
  jq -r '[
    (.agent_state // "idle"),
    (.model.display_name // ""),
    (.vcs.branch // ""),
    (.vcs.dirty // false),
    (.context_window.used_percentage // 0)
  ] | join("|")'
)

reset=$'\e[0m'
dim=$'\e[2m'
sep="${dim} ╱ ${reset}"

case $state in
  idle)             icon=$'\e[92m●' ;;
  thinking)         icon=$'\e[93m◆' ;;
  working|tool_use) icon=$'\e[96m⚙' ;;
  *)                icon=$'\e[97m…' ;;
esac

line="${icon} ${state}${reset}"

if [[ -n $model ]]; then
  line+="${sep}${model}"
fi

if [[ -n $branch ]]; then
  if [[ $dirty == true ]]; then
    line+="${sep}"$'\e[91m'"${branch}"$'\e[93m*'"${reset}"
  else
    line+="${sep}"$'\e[94m'"${branch}${reset}"
  fi
fi

pct=$(LC_NUMERIC=C printf '%.0f' "$used")
if ((pct >= 90)); then
  color=$'\e[91m'
elif ((pct >= 60)); then
  color=$'\e[93m'
else
  color=''
fi
line+="${sep}ctx ${color}${pct}%${reset}"

printf '%s\n' "$line"
