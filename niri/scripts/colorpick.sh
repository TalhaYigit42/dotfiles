#!/usr/bin/env bash
c=$(niri msg pick-color 2>/dev/null | grep -oE '#[0-9A-Fa-f]{6}' | head -1)
[ -n "$c" ] && { printf %s "$c" | wl-copy; notify-send "󰴱  Color copied" "$c"; }
