#!/usr/bin/env bash
# Random wallpaper (or given file) with a transition, via awww.
STATE="$HOME/.cache/niri-wallpaper"
pidof awww-daemon >/dev/null || { setsid awww-daemon >/dev/null 2>&1 & sleep 0.6; }
if [ -n "$1" ]; then img="$1"; else
  img=$(find "$HOME/Pictures/Wallpapers" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | shuf -n1)
fi
[ -f "$img" ] || img=$(cat "$STATE" 2>/dev/null)
[ -f "$img" ] || exit 1
echo "$img" > "$STATE"
awww img "$img" --transition-type grow --transition-pos 0.5,0.5 --transition-duration 1.2 --transition-fps 60
