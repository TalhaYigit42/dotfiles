#!/usr/bin/env bash
# One-line note capture -> ~/Documents/notes/inbox.md   (usage: note.sh ["text"])
mkdir -p ~/Documents/notes
txt="$*"
[ -z "$txt" ] && txt=$(printf '' | rofi -dmenu -p "note" -theme ~/.config/niri/rofi.rasi) || true
[ -z "$txt" ] && exit 0
printf -- '- [%s] %s\n' "$(date '+%F %H:%M')" "$txt" >> ~/Documents/notes/inbox.md
notify-send -t 2000 "note" "saved"
