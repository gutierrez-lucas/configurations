#!/usr/bin/env zsh

DIR="/home/lucas/Work/Heethr"
SCRIPTS_DIR="$DIR/scripts"
SESSION="Heethr"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[heethr]${NC} $1"; }
warn() { echo -e "${YELLOW}[heethr]${NC} $1"; }

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
