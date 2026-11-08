#!/usr/bin/env bash
# Lock with hyprlock (falls back to swaylock if hyprlock is missing).
pidof hyprlock swaylock >/dev/null && exit 0
if command -v hyprlock >/dev/null; then exec hyprlock -c "$HOME/.config/niri/hyprlock.conf"; fi
wall=$(cat "$HOME/.cache/niri-wallpaper" 2>/dev/null); [ -f "$wall" ] || wall="$HOME/Pictures/Wallpapers/lock.jpg"
exec swaylock -f -C "$HOME/.config/niri/swaylock.conf" -i "$wall"
