#!/usr/bin/env zsh

DIR="/home/lucas/Work/Heethr"
SCRIPTS_DIR="$DIR/scripts"
SESSION="Heethr"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[heethr]${NC} $1"; }
warn() { echo -e "${YELLOW}[heethr]${NC} $1"; }
err()  { echo -e "${RED}[heethr]${NC} $1"; }

# ── Safety check: prevent running from inside the Heethr session ──────────────
CURRENT_SESSION=$(tmux display-message -p "#S" 2>/dev/null || echo "")
if [[ "$CURRENT_SESSION" == "$SESSION" ]]; then
  err "ERROR: You're currently inside the '$SESSION' tmux session."
  err "Running this script from inside will log you out!"
  err ""
  err "Solution: Switch to a different tmux window/session first, or:"
  err "  1. Detach: prefix + d"
  err "  2. Then run: close_heethr"
  exit 1
fi

# ── 1. Stop services (ports + optionally DB) ──────────────────────────────────
#    Pass --stop-db to also stop the Docker DB container.
bash "$SCRIPTS_DIR/stop-local-system.sh" "$@"

# ── 2. Kill the tmux session ──────────────────────────────────────────────────
if tmux has-session -t "$SESSION" 2>/dev/null; then
  log "Killing tmux session '$SESSION'..."
  tmux kill-session -t "$SESSION"
  log "Session '$SESSION' closed."
else
  warn "No '$SESSION' session found — nothing to close."
fi
