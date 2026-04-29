#!/usr/bin/env bash

export LC_ALL=en_US.UTF-8

# Ensure ~/.local/bin is in PATH (tmux run-shell doesn't load .zshrc)
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

# Detect OS for gh config path
OS_ID=$(grep -oP '^ID=\K\w+' /etc/os-release 2>/dev/null || echo "unknown")
OS_ID_LIKE=$(grep -oP '^ID_LIKE=\K\w+' /etc/os-release 2>/dev/null || echo "")

# Arch-based distros (Cachyos, Arch) store gh config in ~/.config/gh
# Debian/Ubuntu store gh config in ~/.config/gh as well (XDG standard)
# But some setups use ~/.local/share/gh or a custom path
# Use XDG_CONFIG_HOME if set, otherwise fall back to ~/.config
GH_CONFIG_BASE="${XDG_CONFIG_HOME:-$HOME/.config}"

# If on Arch-based and ~/.config/gh doesn't exist, check ~/.local/share/gh
if [[ "$OS_ID_LIKE" == *"arch"* ]] || [[ "$OS_ID" == "arch" ]]; then
    if [ ! -d "$GH_CONFIG_BASE/gh" ] && [ -d "$HOME/.local/share/gh" ]; then
        export GH_CONFIG_DIR="$HOME/.local/share/gh"
    fi
fi

# Get utils from tmux2k lib dir (the source of truth)
source "$HOME/.tmux/plugins/tmux2k/lib/utils.sh"

icon=$(get_tmux_option "@tmux2k-copilot-icon" "󰊤")

fetch_usage() {
    gh api "/copilot_internal/user" 2>/dev/null
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
