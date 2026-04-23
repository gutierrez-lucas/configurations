#!/usr/bin/env bash
# notify-on-finish.sh <window-name> <command...>
#
# Runs a command and notifies tmux when it finishes by:
# 1. Adding a ⚠ prefix to the window name
# 2. Ringing the bell so tmux can notify
#
# Usage:
#   notify-on-finish.sh "AgentWindow" bash -c "long-running-command"
#   notify-on-finish.sh "Build" make build

WINDOW_NAME="${1:?Usage: notify-on-finish.sh <window-name> <command...>}"
shift

# Run the command
"$@"
EXIT_CODE=$?

# Get the current tmux window/session
if [[ -n "$TMUX" ]]; then
  # Add ⚠ to window name as notification
  tmux rename-window -t "$TMUX_PANE" "⚠ $WINDOW_NAME"
  
  # Ring the bell (configure tmux to send notification)
  tmux send-keys -t "$TMUX_PANE" "printf '\a'" Enter
fi

exit $EXIT_CODE
