#!/usr/bin/env bash

# When sourced from tmux2k plugins dir, this finds tmux2k's lib
# When run directly, we calculate the correct path
if [[ -f "../lib/utils.sh" ]]; then
  source "../lib/utils.sh"
elif [[ -f "$HOME/.tmux/plugins/tmux2k/lib/utils.sh" ]]; then
  source "$HOME/.tmux/plugins/tmux2k/lib/utils.sh"
else
  # Fallback: just output the icon directly
  echo ""
  exit 0
fi

icon=$(get_tmux_option "@tmux2k-calc-icon" "")

echo "$icon"
