#!/usr/bin/env bash
# setup_copilot_gauge.sh — Install the tmux2k copilot gauge plugin
# Copies copilot.sh from ~/.scripts into the tmux2k plugins dir,
# installs gh if missing, ensures the 'user' scope is granted, and
# clears the usage cache so the gauge refreshes immediately.
#
# Usage: bash ~/.scripts/setup_copilot_gauge.sh

set -euo pipefail

info()    { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
success() { printf '\033[1;32m[OK]\033[0m    %s\n' "$*"; }
warn()    { printf '\033[1;33m[WARN]\033[0m  %s\n' "$*"; }
die()     { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_SRC="$SCRIPTS_DIR/copilot.sh"
PLUGIN_DST="$HOME/.tmux/plugins/tmux2k/plugins/copilot.sh"
CACHE_FILE="/tmp/tmux2k_copilot_usage_cache"

# ── 1. Copy plugin ─────────────────────────────────────────────────────────────
copy_plugin() {
    [ -f "$PLUGIN_SRC" ] || die "Source plugin not found: $PLUGIN_SRC"
    local dst_dir
    dst_dir="$(dirname "$PLUGIN_DST")"
    [ -d "$dst_dir" ] || die "tmux2k plugins dir not found: $dst_dir"
    cp "$PLUGIN_SRC" "$PLUGIN_DST"
    chmod +x "$PLUGIN_DST"
    success "copilot.sh copied to $PLUGIN_DST"
}

# ── 2. Install gh if missing ───────────────────────────────────────────────────
install_gh() {
    if command -v gh &>/dev/null; then
        info "gh already installed ($(gh --version | head -1)), skipping."
        return
    fi
    info "Installing GitHub CLI (gh) locally..."
    local VERSION TMP
    VERSION="$(curl -fsSL https://github.com/cli/cli/releases/latest \
        | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*' | head -1 | tr -d 'v')"
    TMP="$(mktemp -d)"
    curl -fsSL "https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_linux_amd64.tar.gz" \
        -o "$TMP/gh.tar.gz"
    tar -xzf "$TMP/gh.tar.gz" -C "$TMP/"
    mkdir -p "$HOME/.local/bin"
    cp "$TMP/gh_${VERSION}_linux_amd64/bin/gh" "$HOME/.local/bin/gh"
    chmod +x "$HOME/.local/bin/gh"
    rm -rf "$TMP"
    success "gh v${VERSION} installed to ~/.local/bin/gh."
}

# ── 3. Ensure gh is authenticated with the 'user' scope ───────────────────────
ensure_gh_auth() {
    if ! gh auth status &>/dev/null; then
        info "gh is not authenticated — starting login..."
        gh auth login -h github.com -p ssh -w
    else
        info "gh is authenticated."
    fi

    # Check for 'user' scope; refresh if missing
    local scopes
    scopes="$(gh auth status 2>&1)"
    if echo "$scopes" | grep -q "'user'"; then
        info "gh token already has 'user' scope."
    else
        info "Refreshing gh token to add 'user' scope..."
        gh auth refresh -h github.com -s user
        success "gh token refreshed with 'user' scope."
    fi
}

# ── 4. Clear stale cache ───────────────────────────────────────────────────────
clear_cache() {
    if [ -f "$CACHE_FILE" ]; then
        rm -f "$CACHE_FILE"
        success "Stale cache removed: $CACHE_FILE"
    else
        info "No cache file found, nothing to remove."
    fi
}

# ── main ───────────────────────────────────────────────────────────────────────
main() {
    info "=== Setting up tmux2k copilot gauge ==="
    copy_plugin
    install_gh
    ensure_gh_auth
    clear_cache
    success "=== Done! The gauge will show usage on the next tmux status refresh. ==="
}

main "$@"
