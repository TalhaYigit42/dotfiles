#!/usr/bin/env bash
# Low-battery notices at 20% and 10%: quiet, short, once per discharge.
b=/sys/class/power_supply/BAT0; w20=0; w10=0
while true; do
  cap=$(cat $b/capacity 2>/dev/null) || exit 0; st=$(cat $b/status)
  if [ "$st" = Discharging ]; then
    [ "$cap" -le 20 ] && [ $w20 = 0 ] && { notify-send -t 4000 "navi" "battery ${cap}%. stay connected."; w20=1; }
    [ "$cap" -le 10 ] && [ $w10 = 0 ] && { notify-send -t 4000 "navi" "battery ${cap}%. your navi is dying."; w10=1; }
  else w20=0; w10=0; fi
  sleep 60
done
