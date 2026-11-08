#!/usr/bin/env bash
# Add a calendar event: type e.g.  "tomorrow 14:30 Dentist"   or  "12.11. 08:00 Exam"
t=$(printf '' | rofi -dmenu -p "event: [day] [hh:mm] title" -theme ~/.config/niri/rofi.rasi) || exit 0
[ -z "$t" ] && exit 0
~/.config/niri/scripts/qs-events.py add "$t" && notify-send -t 2000 "calendar" "saved" || notify-send -t 3500 "calendar" "not understood (e.g. tomorrow 14:30 Dentist)"
