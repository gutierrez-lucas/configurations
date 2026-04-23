#!/usr/bin/env bash
# run-with-alert.sh <command...>
#
# Runs any command and displays an alert indicator in the tmux window title
# when the command finishes. Works for any command automatically.
#
# Usage:
#   run-with-alert.sh make build
#   run-with-alert.sh bash long-script.sh
#   run-with-alert.sh npm run dev

# Get the current window name
if [[ -n "$TMUX_PANE" ]]; then
  ORIGINAL_NAME=$(tmux display-message -p '#{window_name}')
else
  ORIGINAL_NAME="Task"
fi

# Run the command
"$@"
EXIT_CODE=$?

# If in tmux, rename the window to show it finished
if [[ -n "$TMUX_PANE" ]]; then
  if [[ $EXIT_CODE -eq 0 ]]; then
    # Success: show green checkmark
    tmux rename-window "✓ $ORIGINAL_NAME"
  else
    # Failure: show red X
    tmux rename-window "✗ $ORIGINAL_NAME"
  fi
  
  # Ring the bell so terminal can notify
  printf '\a'
fi

exit $EXIT_CODE
