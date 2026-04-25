#!/usr/bin/env bash

export LC_ALL=en_US.UTF-8

# Get utils from tmux2k lib dir (the source of truth)
source "$HOME/.tmux/plugins/tmux2k/lib/utils.sh"

icon=$(get_tmux_option "@tmux2k-copilot-icon" "󰊤")
cache_file="/tmp/tmux2k_copilot_usage_cache"
cache_ttl=60 # 1 minute

fetch_usage() {
    gh api "/copilot_internal/user" 2>/dev/null
}

get_cached_or_fetch() {
    local should_fetch=false
    
    # Decide if we should fetch fresh data
    if [ ! -f "$cache_file" ]; then
        should_fetch=true
    else
        local age=$(( $(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0) ))
        if [ "$age" -ge "$cache_ttl" ]; then
            should_fetch=true
        else
            # Cache is still fresh, use it
            cat "$cache_file"
            return
        fi
    fi
    
    # Try to fetch fresh data
    if [ "$should_fetch" = true ]; then
        local result
        result=$(fetch_usage)
        
        if [ -n "$result" ]; then
            # Successfully fetched — write and return fresh data
            echo "$result" > "$cache_file"
            echo "$result"
            return
        fi
    fi
    
    # If we get here, fetch failed — fall back to stale cache
    if [ -f "$cache_file" ]; then
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
        printf "#[bg=colour196,fg=colour255,bold]%s %s%%#[default]" "$icon" "$pct"
    else
        printf "%s %s%%" "$icon" "$pct"
    fi
}

main
