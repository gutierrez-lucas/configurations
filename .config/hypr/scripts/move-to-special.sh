#!/bin/bash
# Move the active window to the per-monitor special workspace.
# Usage: move-to-special.sh [workspace-name-suffix]

SUFFIX="${1:-magic}"

MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

if [[ -z "$MONITOR" ]]; then
	exit 1
fi

SAFE_MONITOR="${MONITOR//[^a-zA-Z0-9]/_}"
WORKSPACE_NAME="${SAFE_MONITOR}_${SUFFIX}"

hyprctl dispatch movetoworkspace "special:${WORKSPACE_NAME}"
