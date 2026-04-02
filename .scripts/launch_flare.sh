#!/usr/bin/env zsh

DIR="/home/lucas/Work/FlareSense"
SESSION="Flare"

if [[ "$1" == "--isolate" ]]; then
  # Launch a new Alacritty window with a dedicated tmux session
  alacritty -e tmux new-session -s "$SESSION" -c "$DIR" \; \
    split-window -v -c "$DIR" \; \
    send-keys -t "$SESSION:0.0" "nvim ." Enter \; \
    send-keys -t "$SESSION:0.1" "exportidf && cd $DIR" Enter \; \
    select-pane -t "$SESSION:0.0" \; \
    rename-window "Flare" &
  exit 0
fi

WINDOW=$(tmux display-message -p '#S:#I')

# Rename the current window
tmux rename-window -t "$WINDOW" "Flare"

# Set the current window's working directory and split
tmux send-keys -t "$WINDOW" "cd $DIR" Enter

# Split the current window horizontally (upper/lower panes)
tmux split-window -t "$WINDOW" -v -c "$DIR"

# Upper pane (pane 0): open nvim
tmux send-keys -t "$WINDOW.0" "nvim ." Enter

# Bottom pane (pane 1): run exportidf alias then cd to root dir
tmux send-keys -t "$WINDOW.1" "exportidf && cd $DIR" Enter

# Focus the upper pane
tmux select-pane -t "$WINDOW.0"
