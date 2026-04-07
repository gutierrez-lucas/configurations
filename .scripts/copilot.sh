#!/usr/bin/env bash

export LC_ALL=en_US.UTF-8

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

icon=$(get_tmux_option "@tmux2k-copilot-icon" "󰊤")
cache_file="/tmp/tmux2k_copilot_usage_cache"
cache_ttl=900 # 15 minutes

fetch_usage() {
    /home/lucas/.local/bin/gh api "/users/gutierrez-lucas/settings/billing/premium_request/usage" \
        -H "X-GitHub-Api-Version: 2022-11-28" 2>/dev/null
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

    local used limit pct
    used=$(echo "$json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
total = sum(item['grossQuantity'] for item in data.get('usageItems', []))
print(int(total))
" 2>/dev/null)

    local discount
    discount=$(echo "$json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
total = sum(item['discountQuantity'] for item in data.get('usageItems', []))
print(int(total))
" 2>/dev/null)

    if [ -z "$used" ] || [ -z "$discount" ]; then
        echo "$icon --"
        return
    fi

    # Auto-detect plan limit from discount total
    if [ "$discount" -gt 300 ]; then
        limit=1500  # Pro+
    elif [ "$discount" -gt 50 ]; then
        limit=300   # Pro
    else
        limit=50    # Free
    fi

    if [ "$limit" -gt 0 ]; then
        pct=$(( used * 100 / limit ))
    else
        pct=0
    fi

    echo "$icon ${pct}%"
}

main
