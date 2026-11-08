#!/usr/bin/env bash
# Waybar JSON for Spotify via playerctl (follows the player).
emit() { jq -nc --arg t "$1" --arg c "$2" --arg tip "$3" '{text:$t,class:$c,tooltip:$tip}'; }
while true; do
  emit "" stopped ""
  playerctl -p spotify -F metadata --format $'{{status}}\t{{artist}}\t{{title}}\t{{album}}' 2>/dev/null |
  while IFS=$'\t' read -r st ar ti al; do
    if [ -z "$ti" ]; then emit "" stopped ""; continue; fi
    cls=$(echo "$st" | tr 'A-Z' 'a-z')
    :
    icon=$''; [ "$cls" = paused ] && icon=$''
    emit "$icon  $ti" "$cls" "$ti"$'\n'"$ar"$'\n'"$al"$'\n\n'"click: play/pause · right: next · middle: previous · scroll: volume"
  done
  sleep 2
done
