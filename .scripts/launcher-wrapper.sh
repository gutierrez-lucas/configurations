#!/usr/bin/env zsh
# launcher-wrapper.sh — called directly by the tmux mouse binding.
# Runs in the binding's client context, so it can chain tmux popups reliably.

SCRIPTS_DIR="$HOME/.scripts"
RESULT=$(mktemp)
trap "rm -f '$RESULT'" EXIT

# ── 1. Open the compact launcher menu ────────────────────────────────────────
# tmux popup here is synchronous — this blocks until the user picks or exits.
tmux popup -w 44 -h 12 -E "zsh '$SCRIPTS_DIR/launcher-popup.sh' '$RESULT'"

# ── 2. Act on the selection ───────────────────────────────────────────────────
selection=$(cat "$RESULT" 2>/dev/null)

case "$selection" in
  projects) tmux popup -w 80% -h 72% -E "zsh '$SCRIPTS_DIR/projects.sh'" ;;
esac
