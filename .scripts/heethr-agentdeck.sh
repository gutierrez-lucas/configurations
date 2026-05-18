#!/usr/bin/env bash

set -euo pipefail

TITLE="Heethr Commander"
GROUP="heethr"
WORKDIR="/home/lucas/Work/Heethr"

usage() {
  cat <<'EOF'
Usage: heethr-agentdeck.sh <ensure|attach|remove|deck>

Commands:
  ensure  Create the Heethr Commander session if missing and start it if needed
  attach  Ensure the session exists, then attach to it
  remove  Stop and remove the session if it exists
  deck    Open the agent-deck TUI inside tmux
EOF
}

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    printf '%s not found on PATH\n' "$tool" >&2
    exit 1
  fi
}

session_exists() {
  agent-deck session show "$TITLE" -q >/dev/null 2>&1
}

session_status() {
  agent-deck session show "$TITLE" --json 2>/dev/null | jq -r '.status // empty'
}

ensure_session() {
  require_tool agent-deck
  require_tool jq
  require_tool opencode

  if ! session_exists; then
    agent-deck add "$WORKDIR" -t "$TITLE" -g "$GROUP" -c opencode
    agent-deck session start "$TITLE"
    printf 'created and started %s\n' "$TITLE"
    return 0
  fi

  case "$(session_status)" in
    running|waiting|idle|starting)
      printf '%s already available\n' "$TITLE"
      ;;
    *)
      agent-deck session start "$TITLE"
      printf 'started %s\n' "$TITLE"
      ;;
  esac
}

attach_session() {
  ensure_session
  agent-deck session attach "$TITLE"
}

remove_session() {
  require_tool agent-deck

  if ! session_exists; then
    printf '%s not found\n' "$TITLE"
    return 0
  fi

  agent-deck session stop "$TITLE" >/dev/null 2>&1 || true
  agent-deck remove "$TITLE"
  printf 'removed %s\n' "$TITLE"
}

open_deck() {
  require_tool agent-deck
  AGENT_DECK_ALLOW_OUTER_TMUX=1 agent-deck
}

case "${1:-}" in
  ensure)
    ensure_session
    ;;
  attach)
    attach_session
    ;;
  remove)
    remove_session
    ;;
  deck)
    open_deck
    ;;
  -h|--help|help|"")
    usage
    ;;
  *)
    printf 'unknown command: %s\n\n' "$1" >&2
    usage >&2
    exit 1
    ;;
esac
