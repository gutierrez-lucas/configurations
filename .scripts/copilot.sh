#!/usr/bin/env bash

export LC_ALL=en_US.UTF-8

# Get utils from tmux2k lib dir (the source of truth)
source "$HOME/.tmux/plugins/tmux2k/lib/utils.sh"

icon=$(get_tmux_option "@tmux2k-copilot-icon" "󰊤")

fetch_usage() {
    "$HOME/.local/bin/gh" api "/copilot_internal/user" 2>/dev/null
}

main() {
    local json
    json=$(fetch_usage)

    if [ -z "$json" ]; then
        echo "$icon --"
        return
    fi

    local pct
    pct=$(echo "$json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
pi = data.get('quota_snapshots', {}).get('premium_interactions', {})
pct_remaining = pi.get('percent_remaining')
if pct_remaining is None:
    print('--')
else:
    used_pct = 100 - pct_remaining
    print(f'{used_pct:.1f}')
" 2>/dev/null)

    if [ -z "$pct" ] || [ "$pct" = "--" ]; then
        echo "$icon --"
        return
    fi

    # Output without color codes - let tmux2k handle coloring
    printf "%s %s%%" "$icon" "$pct"
}

main
