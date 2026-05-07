#!/usr/bin/env zsh
# close_heethr_browser.sh — Closes only the Heethr Chrome windows/tabs.
#
# Uses xdotool to find Chrome windows that have the Heethr URLs (localhost:3003 or
# localhost:3001) and closes only those windows. Other Chrome windows with other
# tabs remain open and untouched.
#
# Usage:
#   close_heethr_browser.sh  — via lifecycle in heethr.json

set -euo pipefail

GREEN=$'\033[38;5;114m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m'

log()  { echo "${GREEN}[heethr-browser]${NC} $1"; }
warn() { echo "${YELLOW}[heethr-browser]${NC} $1"; }

# Find Chrome windows that have the Heethr local URLs in their title
# Chrome window titles contain the URL of the active tab
HEETHR_WINDOWS=$(xdotool search --name "localhost:3003\|localhost:3001" 2>/dev/null || true)

if [[ -z "$HEETHR_WINDOWS" ]]; then
  warn "No Heethr Chrome windows found (may already be closed)."
else
  HEETHR_WIN_COUNT=$(echo "$HEETHR_WINDOWS" | wc -l | tr -d ' ')
  log "Closing $HEETHR_WIN_COUNT Heethr Chrome window(s)..."
  echo "$HEETHR_WINDOWS" | while read -r win_id; do
    [[ -z "$win_id" ]] && continue
    xdotool windowclose "$win_id" 2>/dev/null || true
  done
fi

log "Browser cleanup done."
