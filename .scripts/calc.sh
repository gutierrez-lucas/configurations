#!/usr/bin/env bash

current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$current_dir/../lib/utils.sh"

icon=$(get_tmux_option "@tmux2k-calc-icon" "$(printf '\xef\x87\xac')")

echo "$icon"
