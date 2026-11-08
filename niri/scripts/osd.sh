#!/usr/bin/env bash
# osd.sh vol-up|vol-down|vol-mute|mic-mute|bri-up|bri-down
# changes the value, then shows the on-screen display (Quickshell). Works even with "Do not disturb".
show() { qs -c sidebar ipc call osd popup "$1" "$2" "$3" >/dev/null 2>&1 || notify-send -t 1200 -h string:x-canonical-private-synchronous:osd "$1 $2%"; }
vol() { local o; o=$(wpctl get-volume @DEFAULT_AUDIO_SINK@); local v; v=$(awk '{printf "%d",$2*100}' <<<"$o"); grep -q MUTED <<<"$o" && m=true || m=false; show vol "$v" "$m"; }
case "$1" in
  vol-up)   wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+; vol ;;
  vol-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-; vol ;;
  vol-mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle; vol ;;
  mic-mute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
            wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED && m=true || m=false; show mic 0 "$m" ;;
  bri-up)   brightnessctl -q set 5%+;  show bri "$(brightnessctl -m | cut -d, -f4 | tr -d %)" false ;;
  bri-down) brightnessctl -q set 5%-;  show bri "$(brightnessctl -m | cut -d, -f4 | tr -d %)" false ;;
esac
