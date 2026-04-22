#!/bin/zsh

# Ensure tmux.conf exists
if [ -f ~/.tmux.conf ]; then
  tmux new-session \; source-file ~/.tmux.conf
else
  echo "No ~/.tmux.conf found, starting plain tmux..."
  tmux new-session -A -s main
fi

