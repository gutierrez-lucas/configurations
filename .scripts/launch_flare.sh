#!/usr/bin/env zsh

DIR="/home/lucas/Work/FlareSense"
SESSION="FlareSense"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[flaresense]${NC} $1"; }
warn() { echo -e "${YELLOW}[flaresense]${NC} $1"; }

# ── Attach shortcut ───────────────────────────────────────────────────────────
if [[ "$1" == "attach" ]]; then
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    tmux attach-session -t "$SESSION"
  else
    echo "No '$SESSION' session found."
    exit 1
  fi
  exit 0
fi

# ── Kill existing session ─────────────────────────────────────────────────────
if tmux has-session -t "$SESSION" 2>/dev/null; then
  warn "Killing existing '$SESSION' session..."
  tmux kill-session -t "$SESSION"
fi

# ── 1. Create session — Shell window ─────────────────────────────────────────
#    No direct pane command: exportidf is a zsh alias and must be sent via
#    send-keys into an already-running interactive shell.
tmux new-session -d -s "$SESSION" -n "Shell" -c "$DIR"
tmux run-shell -t "$SESSION:Shell" "tmux source-file ~/.tmux.conf"
tmux send-keys -t "$SESSION:Shell" "exportidf" Enter

# ── 2. IDE window ─────────────────────────────────────────────────────────────
tmux new-window -t "$SESSION:" -n "IDE" -c "$DIR"
tmux send-keys -t "$SESSION:IDE" "exportidf && nvim ." Enter

# ── 3. Focus the IDE window ───────────────────────────────────────────────────
tmux select-window -t "$SESSION:IDE"

# ── 4. Open Alacritty and attach (or attach here if --here is passed) ─────────
if [[ "$1" == "--here" ]]; then
  log "Session '$SESSION' created — attaching here."
  tmux switch-client -t "$SESSION"
else
  alacritty -e tmux attach-session -t "$SESSION" &
  log "Session '$SESSION' created — opening Alacritty."
fi
echo ""
echo "  Windows (in order):"
echo "    Shell — exportidf sourced, shell at $DIR"
echo "    IDE   — exportidf sourced, nvim at $DIR"
echo ""
echo "  ./launch_flare.sh attach — reattach to this session"
echo ""
