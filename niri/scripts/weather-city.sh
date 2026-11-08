#!/usr/bin/env bash
c=$(printf '' | rofi -dmenu -p "city for the weather" -theme ~/.config/niri/rofi.rasi) || exit 0
[ -z "$c" ] && exit 0
printf '%s' "$c" > ~/.config/niri/weather.city; rm -f ~/.cache/qs-weather.json
notify-send -t 2000 "weather" "city: $c"
