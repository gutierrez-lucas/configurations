#!/usr/bin/env zsh

DIR="/home/lucas/Work/Heethr"
BACKEND_DIR="$DIR/snow-melting-backend"
FRONTEND_DIR="$DIR/snow_melting_dashboard"
SHOP_DIR="$DIR/snow_melting_dashboard-shop"
SESSION="Heethr"
WINDOW_NAME="heethr"
NVIM_WINDOW="nvim"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${GREEN}[heethr]${NC} $1"; }
warn() { echo -e "${YELLOW}[heethr]${NC} $1"; }

# ── Kill every process listening on a given port ──────────────────────────────
free_port() {
  local PORT=$1
  local PIDS
  PIDS=$(lsof -ti tcp:"$PORT" 2>/dev/null || true)
  if [ -n "$PIDS" ]; then
    warn "Port $PORT in use — killing PIDs: $PIDS"
    for PID in $PIDS; do
      PGID=$(ps -o pgid= -p "$PID" 2>/dev/null | tr -d ' ')
      if [ -n "$PGID" ] && [ "$PGID" != "0" ]; then
        kill -9 -- "-$PGID" 2>/dev/null || true
      else
        kill -9 "$PID" 2>/dev/null || true
      fi
    done
    sleep 0.5
  fi
}

# ── Prep: free ports & raise inotify limit ────────────────────────────────────
prep() {
  log "Freeing ports 3000, 5173, 3003 if already in use..."
  free_port 3000
  free_port 5173
  free_port 3003

  local CURRENT_WATCHERS
  CURRENT_WATCHERS=$(cat /proc/sys/fs/inotify/max_user_watches 2>/dev/null || echo 0)
  if [ "$CURRENT_WATCHERS" -lt 524288 ]; then
    log "Raising inotify max_user_watches to 524288 (was $CURRENT_WATCHERS)..."
    sudo sysctl -qw fs.inotify.max_user_watches=524288 || \
      warn "Could not raise inotify limit — you may hit ENOSPC on file watchers."
  fi

  log "Starting local PostgreSQL (Docker)..."
  bash "$DIR/db/start-local-db.sh"
  log "Waiting for PostgreSQL to be ready..."
  until docker exec heethr-db pg_isready -U heethr -d heethr_dev -q 2>/dev/null; do
    sleep 1
  done
  log "PostgreSQL is ready."
}

# ── Commands for each pane ────────────────────────────────────────────────────
CMD_BACKEND="cd \"$BACKEND_DIR\" \
  && echo '[backend] Installing dependencies...' \
  && yarn install \
  && set -a && source .env && set +a \
  && echo '[backend] Running migrations...' \
  && (npm run migrations || echo '[backend] Migrations warning — continuing...') \
  && echo '[backend] Starting NestJS...' \
  && yarn start:dev"

CMD_DASHBOARD="cd \"$FRONTEND_DIR\" \
  && echo '[dashboard] Installing dependencies...' \
  && npm install \
  && echo '[dashboard] Starting Vite on :5173...' \
  && npm run dev"

CMD_SHOP="cd \"$SHOP_DIR\" \
  && echo '[shop] Installing dependencies...' \
  && npm install \
  && echo '[shop] Starting Vite on :3003...' \
  && npm run dev"

CMD_DB_LOGS="docker logs -f heethr-db"

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

# ── Default: launch a new Alacritty window with a dedicated tmux session ──────
prep

# Kill existing session if present
if tmux has-session -t "$SESSION" 2>/dev/null; then
  warn "Killing existing '$SESSION' session..."
  tmux kill-session -t "$SESSION"
fi

# Open a new Alacritty window. Mirror the exact pattern from launch_flare.sh:
# pass everything as a single tmux \; chain so the session, layout, and config
# are all set up before attach. source-file ~/.tmux.conf (the same trick used
# in ~/.tmux/tmux-start.sh) ensures the prefix remap and plugins are loaded.
alacritty -e tmux new-session -s "$SESSION" -n "$WINDOW_NAME" -c "$DIR" \; \
  source-file ~/.tmux.conf \; \
  split-window -h -t "$SESSION:$WINDOW_NAME.0" \; \
  split-window -v -t "$SESSION:$WINDOW_NAME.0" \; \
  split-window -v -t "$SESSION:$WINDOW_NAME.1" \; \
  select-layout -t "$SESSION:$WINDOW_NAME" tiled \; \
  set-option -t "$SESSION:$WINDOW_NAME" pane-border-status top \; \
  set-option -t "$SESSION:$WINDOW_NAME" pane-border-format " #{pane_title} " \; \
  select-pane -t "$SESSION:$WINDOW_NAME.0" -T "  Backend :3000" \; \
  select-pane -t "$SESSION:$WINDOW_NAME.1" -T "  Admin Dashboard :5173" \; \
  select-pane -t "$SESSION:$WINDOW_NAME.2" -T "  Shop :3003" \; \
  select-pane -t "$SESSION:$WINDOW_NAME.3" -T "  DB logs" \; \
  send-keys -t "$SESSION:$WINDOW_NAME.0" "$CMD_BACKEND"   Enter \; \
  send-keys -t "$SESSION:$WINDOW_NAME.1" "$CMD_DASHBOARD" Enter \; \
  send-keys -t "$SESSION:$WINDOW_NAME.2" "$CMD_SHOP"      Enter \; \
  send-keys -t "$SESSION:$WINDOW_NAME.3" "$CMD_DB_LOGS"   Enter \; \
  select-pane -t "$SESSION:$WINDOW_NAME.0" \; \
  new-window -n "$NVIM_WINDOW" -c "$DIR" \; \
  send-keys -t "$SESSION:$NVIM_WINDOW" "nvim ." Enter \; \
  select-window -t "$SESSION:$WINDOW_NAME" &

log "Launched Alacritty with tmux session '$SESSION'."
echo ""
echo "  Windows:"
echo "    1. $WINDOW_NAME  — services (backend, dashboards, DB logs)"
echo "    2. $NVIM_WINDOW       — nvim at project root"
echo ""
echo "  Pane navigation:"
echo "    Ctrl+s arrow keys    — move between panes"
echo "    Ctrl+s z             — zoom pane to fullscreen (toggle)"
echo "    Ctrl+s d             — detach (everything keeps running)"
echo "    Ctrl+s w             — window list"
echo "    Ctrl+s 1 / 2         — switch windows"
echo "    ./launch_heethr.sh attach — reattach to this session"
echo ""
echo "  Services:"
echo "    Backend         → http://localhost:3000"
echo "    Swagger         → http://localhost:3000/swagger"
echo "    Admin dashboard → http://localhost:5173"
echo "    Shop dashboard  → http://localhost:3003"
echo "    Database        → localhost:5432 (heethr / heethr_local / heethr_dev)"
echo ""
warn "DB container stays running when this window is closed."
echo ""
