#!/usr/bin/env zsh
# new-session.sh — create a new tmux session interactively
# Called from the project launcher; prompts for session name and creates
# a detached session with ~/.tmux.conf sourced, then attaches to the
# original tmux client (not the popup).

set -euo pipefail

RESULT=$(mktemp)
trap "rm -f '$RESULT'" EXIT

# ── Prompt for session name ──────────────────────────────────────────────────
# Use fzf in reverse layout to collect input; default to "Playground".
tmux popup -w 40 -h 6 -E "echo -n '' | fzf --prompt='Session name: ' --print-query --height=1 --layout=reverse --border=none --no-mouse > '$RESULT'"
QUERY=$(cat "$RESULT" | head -1 | tr -d '\n')
SESSION_NAME="${QUERY:-Playground}"

# ── Validate ─────────────────────────────────────────────────────────────────
if [[ -z "$SESSION_NAME" ]]; then
  SESSION_NAME="Playground"
fi

# Sanitize: only allow alphanumeric, underscore, hyphen
SANITIZED=$(echo "$SESSION_NAME" | tr -cd '[:alnum:]_-')
if [[ -z "$SANITIZED" ]]; then
  SANITIZED="Playground"
fi

# ── Kill existing session if present ────────────────────────────────────────
if tmux has-session -t "$SANITIZED" 2>/dev/null; then
  tmux kill-session -t "$SANITIZED"
fi

# ── Create session (detached) ────────────────────────────────────────────────
tmux new-session -d -s "$SANITIZED" -c "$HOME"

# ── Source ~/.tmux.conf ─────────────────────────────────────────────────────
tmux source-file ~/.tmux.conf

# ── Attach: switch the ORIGINAL client to the new session ──────────────────
# We need to switch the client that launched the popup, not the popup itself.
# The popup's client is the current client (#{client_key}), so we find another
# client and switch that one.
POPUP_CLIENT=$(tmux display-message -p '#{client_key}')

# Find the first client that isn't the popup
TARGET_CLIENT=$(tmux list-clients -F '#{client_key}' | grep -v "^${POPUP_CLIENT}$" | head -1)

if [[ -n "$TARGET_CLIENT" ]]; then
  # Switch the original client to the new session
  tmux switch-client -t "$SANITIZED" -c "$TARGET_CLIENT"
else
  # Fallback: attach normally if no other client found
  tmux attach-session -t "$SANITIZED"
fi
