#!/usr/bin/env zsh

DIR="/home/lucas/Work/Heethr"
SCRIPTS_DIR="$DIR/scripts"
SESSION="Heethr"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

RED='\033[0;31m'

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
  err "  2. Then run: launch_heethr"
  exit 1
fi

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

# ── 1. Create session — start script is the direct pane command ───────────────
#    Passing the command as the last arg to new-session means it runs in the
#    pane immediately, with no send-keys race condition.
tmux new-session -d -s "$SESSION" -n "start" -c "$DIR" \
  "bash $SCRIPTS_DIR/start-local-system.sh"

# ── 2. IDE window ─────────────────────────────────────────────────────────────
tmux new-window -t "$SESSION:" -n "IDE" -c "$DIR"
tmux send-keys -t "$SESSION:IDE" "nvim ." Enter

# ── 3. OpenCode window ────────────────────────────────────────────────────────
#    Plain shell at project root — not "heethr" to avoid clashing with the
#    service window that start-local-system.sh creates inside this session.
tmux new-window -t "$SESSION:" -n "OpenCode" -c "$DIR"

# ── 4. Monitor window ─────────────────────────────────────────────────────────
tmux new-window -t "$SESSION:" -n "Monitor" -c "$DIR"

# ── 5. Focus the start window ─────────────────────────────────────────────────
tmux select-window -t "$SESSION:start"

# ── 6. Open Alacritty and attach (or attach here if --here is passed) ─────────
if [[ "$1" == "--here" ]]; then
  log "Session '$SESSION' created — attaching here."
  tmux switch-client -t "$SESSION"
else
  alacritty -e tmux attach-session -t "$SESSION" &
  log "Session '$SESSION' created — opening Alacritty."
fi
echo ""
echo "  Windows (in order):"
echo "    start   — start-local-system.sh (setup output)"
echo "    heethr  — service panes: backend, dashboards, DB logs"
echo "    IDE     — nvim at $DIR"
echo "    OpenCode — shell at $DIR"
echo "    Monitor — shell at $DIR"
echo ""
echo "  ./launch_heethr.sh attach — reattach to this session"
echo ""
