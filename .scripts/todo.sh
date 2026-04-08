#!/usr/bin/env bash

TODO_FILE="$HOME/Documents/notes/VaultTec/_TODO.md"

case "$1" in
    add)
        shift
        if [ $# -eq 0 ]; then
            echo "Usage: todo add <item description>"
            exit 1
        fi
        ITEM="$*"
        # Ensure file ends with a newline before appending
        if [ -s "$TODO_FILE" ] && [ "$(tail -c1 "$TODO_FILE" | wc -l)" -eq 0 ]; then
            printf "\n" >> "$TODO_FILE"
        fi
        echo "- [ ] $ITEM" >> "$TODO_FILE"
        echo "Added: - [ ] $ITEM"
        ;;
    list)
        glow "$TODO_FILE"
        ;;
    edit)
        vim "$TODO_FILE"
        ;;
    *)
        echo "Usage: todo <add|list|edit> [item]"
        exit 1
        ;;
esac
