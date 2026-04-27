#!/bin/sh

set -eu

is_on_ac() {
    for online in /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; do
        [ -e "$online" ] || continue
        [ "$(cat "$online")" = "1" ] && return 0
    done

    return 1
}

dpms_on() {
    hyprctl dispatch dpms on >/dev/null 2>&1 || true

    if command -v brightnessctl >/dev/null 2>&1; then
        brightnessctl -r >/dev/null 2>&1 || true
    fi
}

case "${1:-}" in
    hold-lid-inhibitor)
        exec systemd-inhibit --what=handle-lid-switch --why="Handle lid close in Hyprland" sh -c 'while :; do sleep 3600; done'
        ;;
    lid-close-action)
        if is_on_ac; then
            loginctl lock-session
        else
            systemctl suspend
        fi
        ;;
    lock-if-ac)
        is_on_ac && loginctl lock-session
        ;;
    dpms-off-if-battery)
        is_on_ac || hyprctl dispatch dpms off
        ;;
    dpms-off-if-ac)
        is_on_ac && hyprctl dispatch dpms off
        ;;
    suspend-if-battery)
        is_on_ac || systemctl suspend
        ;;
    dpms-on)
        dpms_on
        ;;
    *)
        printf 'Usage: %s {hold-lid-inhibitor|lid-close-action|lock-if-ac|dpms-off-if-battery|dpms-off-if-ac|suspend-if-battery|dpms-on}\n' "$0" >&2
        exit 1
        ;;
esac
