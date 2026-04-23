#!/usr/bin/env bash

export LC_ALL=en_US.UTF-8

# Get utils from tmux2k lib dir (the source of truth)
source "$HOME/.tmux/plugins/tmux2k/lib/utils.sh"

icon=$(get_tmux_option "@tmux2k-copilot-icon" "󰊤")
cache_file="/tmp/tmux2k_copilot_usage_cache"
cache_ttl=300 # 5 minutes

fetch_usage() {
    gh api "/copilot_internal/user" 2>/dev/null
}

get_cached_or_fetch() {
    if [ -f "$cache_file" ]; then
        local age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
        if [ "$age" -lt "$cache_ttl" ]; then
            cat "$cache_file"
            return
        fi
    fi
    local result
    result=$(fetch_usage)
    if [ -n "$result" ]; then
        echo "$result" > "$cache_file"
        echo "$result"
    elif [ -f "$cache_file" ]; then
        # API failed — return stale cache rather than nothing
        cat "$cache_file"
    fi
}

main() {
    local json
    json=$(get_cached_or_fetch)

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

    # Check if consumption is over 100% and apply red background with high contrast
    if (( $(echo "$pct > 100" | bc -l) )); then
        # Red background (colour196) with white (colour255) text, bold
        # Reset to default after to avoid leaking into adjacent elements
        printf "#[bg=colour196,fg=colour255,bold]%s %s%%#[default]" "$icon" "$pct"
    else
        printf "%s %s%%" "$icon" "$pct"
    fi
}

main
