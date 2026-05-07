#!/usr/bin/env zsh
# launch_mobile.sh — Adds a Mobile window to the existing Heethr tmux session.
#
# Usage:
#   launch_mobile.sh           — run from within the launcher system

set -euo pipefail

GREEN=$'\033[38;5;114m'
YELLOW=$'\033[1;33m'
RED='\033[0;31m'
NC=$'\033[0m'

log()  { echo "${GREEN}[heethr-mobile]${NC} $1"; }
warn() { echo "${YELLOW}[heethr-mobile]${NC} $1"; }

SESSION="Heethr"
WINDOW_NAME="Mobile"
REPO_ROOT="/home/lucas/Work/Heethr"
MOBILE_DIR="$REPO_ROOT/snow-melting_mobile"
MOBILE_LAUNCH="$HOME/.scripts/start-local-mobile-tmux.sh"

# Guard: Heethr session must exist
if ! tmux has-session -t "$SESSION" 2>/dev/null; then
  warn "Heethr tmux session '$SESSION' not found."
  warn "Start the Heethr system first using: start"
  exit 1
fi

# Guard: backend must be running
if ! curl -s "http://localhost:3000/swagger" > /dev/null 2>&1; then
  warn "Heethr backend is not running at http://localhost:3000."
  warn "Start the Heethr system first using: start"
  exit 1
fi

# Check if Mobile window already exists
EXISTING_WIN=$(tmux list-windows -t "$SESSION" -F "#{window_index}:#{window_name}" 2>/dev/null \
  | grep ":${WINDOW_NAME}$" | cut -d: -f1 | head -1 || true)
if [[ -n "$EXISTING_WIN" ]]; then
  warn "Mobile window already exists in session '$SESSION' (index $EXISTING_WIN)."
  warn "Switching to it instead."
  tmux select-window -t "$SESSION:$EXISTING_WIN"
  exit 0
fi

# Create Mobile window
log "Creating 'Mobile' window in Heethr session..."
tmux new-window -t "$SESSION:" -n "$WINDOW_NAME" -c "$REPO_ROOT"

sleep 0.3

# Launch Flutter via the dedicated launcher script
log "Launching Flutter in Chrome..."
tmux send-keys -t "$SESSION:$WINDOW_NAME" "bash $MOBILE_LAUNCH" Enter

# Focus the window
tmux select-window -t "$SESSION:$WINDOW_NAME"

log "Mobile window ready."
