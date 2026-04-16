#!/usr/bin/env zsh
# launcher-standalone.sh — top-level launcher for Hyprland keybind.
# Runs entirely in a plain terminal (no tmux required).

SCRIPTS_DIR="$HOME/.scripts"
RESULT=$(mktemp)
trap "rm -f '$RESULT'" EXIT

zsh "$SCRIPTS_DIR/launcher-popup.sh" "$RESULT"

selection=$(cat "$RESULT" 2>/dev/null)

case "$selection" in
  calc)     bash "$SCRIPTS_DIR/calc-popup.sh" ;;
  projects) zsh  "$SCRIPTS_DIR/projects.sh"   ;;
  dolar)    bash "$SCRIPTS_DIR/dolar-popup.sh" ;;
esac
