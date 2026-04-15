#!/bin/bash
# Toggle a per-monitor special workspace on the currently focused monitor.
# Usage: toggle-special.sh [workspace-name-suffix]
#   The special workspace will be named "special:<monitor>_<suffix>"
#   so each monitor gets its own independent scratchpad.

SUFFIX="${1:-magic}"

# Get the name of the focused monitor
MONITOR=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name')

if [[ -z "$MONITOR" ]]; then
	exit 1
fi

# Sanitize monitor name (replace special chars with underscores)
SAFE_MONITOR="${MONITOR//[^a-zA-Z0-9]/_}"

WORKSPACE_NAME="${SAFE_MONITOR}_${SUFFIX}"

hyprctl dispatch togglespecialworkspace "$WORKSPACE_NAME"
