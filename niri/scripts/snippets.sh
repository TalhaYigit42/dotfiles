#!/usr/bin/env bash
# Snippet picker: choose a label -> the snippet is copied to the clipboard.
# File: ~/.config/niri/snippets.txt, one per line:  label<TAB>text   (use \n for new lines)
F="$HOME/.config/niri/snippets.txt"
[ "$1" = "--list" ] && { cut -f1 "$F"; exit; }
i=$(cut -f1 "$F" | rofi -dmenu -i -p "snippet" -format i -theme ~/.config/niri/rofi.rasi) || exit 0
txt=$(sed -n "$((i+1))p" "$F" | cut -f2-)
printf '%b' "$txt" | wl-copy
notify-send -t 2000 "snippet" "copied: $(sed -n "$((i+1))p" "$F" | cut -f1)"
