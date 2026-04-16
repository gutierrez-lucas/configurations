#!/usr/bin/env zsh
# close_project.sh <project.json> [extra args passed to stop script]
#
# Generic project closer driven by a project.json definition.
# If lifecycle.stop is defined it is called first, then the tmux session is killed.

set -euo pipefail

if ! command -v jq &>/dev/null; then
  echo "close_project: jq is required but not installed." >&2
  exit 1
fi

JSON="${1:?Usage: close_project.sh <project.json>}"
[[ ! -f "$JSON" ]] && { echo "close_project: file not found: $JSON" >&2; exit 1; }
shift  # remaining args forwarded to the stop script

NAME=$(jq    -r '.name'                  "$JSON")
SESSION=$(jq -r '.session // empty'      "$JSON")
STOP=$(jq    -r '.lifecycle.stop // empty' "$JSON")

GREEN=$'\033[38;5;114m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m'

log()  { echo "${GREEN}[${NAME:l}]${NC} $1"; }
warn() { echo "${YELLOW}[${NAME:l}]${NC} $1"; }

# ── 1. Run stop script if defined ─────────────────────────────────────────────
if [[ -n "$STOP" ]]; then
  if [[ -x "$STOP" ]]; then
    log "Running stop script: $STOP $*"
    bash "$STOP" "$@"
  else
    warn "Stop script not executable: $STOP — skipping."
  fi
fi

# ── 2. Kill tmux session ──────────────────────────────────────────────────────
if [[ -z "$SESSION" ]]; then
  warn "No session defined in $JSON — nothing to kill."
  exit 0
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  log "Killing tmux session '$SESSION'..."
  tmux kill-session -t "$SESSION"
  log "Session '$SESSION' closed."
else
  warn "No '$SESSION' session found — nothing to close."
fi
