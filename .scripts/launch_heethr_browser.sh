#!/usr/bin/env zsh
# launch_heethr_browser.sh — Opens Chrome with Heethr's local apps (Shop + LMS).
#
# Uses the user's default Chrome profile so it gets passwords and session cookies.
# Waits for the backend to be ready before launching.
#
# Usage:
#   launch_heethr_browser.sh  — via lifecycle in heethr.json

set -euo pipefail

GREEN=$'\033[38;5;114m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m'

log()  { echo "${GREEN}[heethr-browser]${NC} $1"; }
warn() { echo "${YELLOW}[heethr-browser]${NC} $1"; }

# Wait for backend to be ready (up to 30s)
log "Waiting for backend at http://localhost:3000..."
for i in {1..30}; do
  if curl -s "http://localhost:3000/swagger" > /dev/null 2>&1; then
    log "Backend is ready."
    break
  fi
  if [[ $i -eq 30 ]]; then
    warn "Backend not ready after 30s — launching Chrome anyway."
  fi
  sleep 1
done

# Launch Chrome with new window using the user's default profile
# This shares passwords, sessions, cookies with the main Chrome
log "Opening Heethr (Shop :3003, LMS :3001)..."

# Use setsid to fully detach from the tmux popup context
setsid env DISPLAY=:0 google-chrome \
  --new-window \
  --profile-directory=Default \
  --no-first-run \
  --window-size=1400,900 \
  --window-position=100,50 \
  http://localhost:3003 \
  http://localhost:3001 \
  </dev/null &>/dev/null &

sleep 2

log "Chrome opened with your default profile."
log "(Stop will close only the Heethr tabs, not your other Chrome windows.)"

# Ensure tmux stays on Heethr session after this script finishes.
CURRENT_CLIENT=$(tmux display-message -p '#{client_session}' 2>/dev/null || true)
if [[ -n "$CURRENT_CLIENT" ]]; then
  tmux switch-client -t Heethr 2>/dev/null || true
fi
