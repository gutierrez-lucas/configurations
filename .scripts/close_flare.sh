#!/usr/bin/env zsh

SESSION="FlareSense"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[flaresense]${NC} $1"; }
warn() { echo -e "${YELLOW}[flaresense]${NC} $1"; }

if tmux has-session -t "$SESSION" 2>/dev/null; then
  log "Killing tmux session '$SESSION'..."
  tmux kill-session -t "$SESSION"
  log "Session '$SESSION' closed."
else
  warn "No '$SESSION' session found — nothing to close."
fi
