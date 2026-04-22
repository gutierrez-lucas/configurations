#!/usr/bin/env zsh
# launch_project.sh <project.json> [--here]
#
# Generic project launcher driven by a project.json definition.
# See .scripts/projects/project.schema.json for the full schema.
#
# Usage:
#   launch_project.sh heethr.json          — opens new Alacritty window
#   launch_project.sh heethr.json --here   — switches current tmux client

set -euo pipefail

# ── Dependency check ──────────────────────────────────────────────────────────
if ! command -v jq &>/dev/null; then
  echo "launch_project: jq is required but not installed." >&2
  exit 1
fi

# ── Args ──────────────────────────────────────────────────────────────────────
JSON="${1:?Usage: launch_project.sh <project.json> [--here]}"
[[ ! -f "$JSON" ]] && { echo "launch_project: file not found: $JSON" >&2; exit 1; }

HERE=false
[[ "${2:-}" == "--here" ]] && HERE=true

# ── Parse top-level fields ────────────────────────────────────────────────────
NAME=$(jq -r '.name'        "$JSON")
DIR=$(jq  -r '.dir'         "$JSON")
SESSION=$(jq -r '.session // empty' "$JSON")

GREEN=$'\033[38;5;114m'
YELLOW=$'\033[1;33m'
NC=$'\033[0m'

log()  { echo "${GREEN}[${NAME:l}]${NC} $1"; }
warn() { echo "${YELLOW}[${NAME:l}]${NC} $1"; }

# ── Guard: session required ───────────────────────────────────────────────────
if [[ -z "$SESSION" ]]; then
  warn "No session defined in $JSON — nothing to launch."
  exit 0
fi

# ── Attach shortcut ───────────────────────────────────────────────────────────
if [[ "${2:-}" == "attach" ]]; then
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

# ── Build windows ─────────────────────────────────────────────────────────────
window_count=$(jq '.tmux.windows | length' "$JSON")

for i in $(seq 0 $((window_count - 1))); do
  win=$(jq -r ".tmux.windows[$i]" "$JSON")

  win_name=$(echo "$win"     | jq -r '.name')
  command=$(echo "$win"      | jq -r '.command   // empty')
  send_keys=$(echo "$win"    | jq -r '.send_keys // empty')
  source_conf=$(echo "$win"  | jq -r '.source_tmux_conf // false')

  if [[ $i -eq 0 ]]; then
    # ── First window: creates the session ────────────────────────────────────
    if [[ -n "$command" ]]; then
      tmux new-session -d -s "$SESSION" -n "$win_name" -c "$DIR" "$command"
    else
      tmux new-session -d -s "$SESSION" -n "$win_name" -c "$DIR"
      [[ -n "$send_keys" ]] && tmux send-keys -t "$SESSION:${win_name}" "$send_keys" Enter
    fi
    [[ "$source_conf" == "true" ]] && \
      tmux run-shell -t "$SESSION:${win_name}" "tmux source-file ~/.tmux.conf"
  else
    # ── Subsequent windows ────────────────────────────────────────────────────
    if [[ -n "$command" ]]; then
      tmux new-window -t "$SESSION:" -n "$win_name" -c "$DIR" "$command"
    else
      tmux new-window -t "$SESSION:" -n "$win_name" -c "$DIR"
      [[ -n "$send_keys" ]] && tmux send-keys -t "$SESSION:${win_name}" "$send_keys" Enter
    fi
    [[ "$source_conf" == "true" ]] && \
      tmux run-shell -t "$SESSION:${win_name}" "tmux source-file ~/.tmux.conf"
  fi
done

# ── Focus window ──────────────────────────────────────────────────────────────
focus=$(jq -r '.tmux.focus // empty' "$JSON")
if [[ -n "$focus" ]]; then
  tmux select-window -t "$SESSION:${focus}"
fi

# ── Open terminal or attach in place ─────────────────────────────────────────
if $HERE; then
  log "Session '$SESSION' created — attaching here."
  tmux switch-client -t "$SESSION"
else
  alacritty -e tmux attach-session -t "$SESSION" &
  log "Session '$SESSION' created — opening Alacritty."
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "  Windows (in order):"
jq -r '.tmux.windows[] | "    \(.name)"' "$JSON"
echo ""
echo "  launch_project.sh $JSON attach — reattach to this session"
echo ""
