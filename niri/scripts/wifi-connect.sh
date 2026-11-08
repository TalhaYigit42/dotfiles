#!/usr/bin/env bash
# wifi-connect.sh SSID : use the saved connection, else ask for the password (rofi) and connect.
ssid="$1"; [ -z "$ssid" ] && exit 1
if nmcli -t -f NAME con show | grep -qxF "$ssid"; then nmcli con up id "$ssid" >/dev/null 2>&1 && { notify-send -t 2500 "wifi" "connected: $ssid"; exit 0; }; fi
sec=$(nmcli -t -f SSID,SECURITY dev wifi list | awk -F: -v s="$ssid" '$1==s{print $2; exit}')
if [ -z "$sec" ] || [ "$sec" = "--" ]; then nmcli dev wifi connect "$ssid" >/dev/null 2>&1 && notify-send -t 2500 "wifi" "connected: $ssid" || notify-send -t 3500 "wifi" "connection failed"; exit; fi
pw=$(printf '' | rofi -dmenu -password -p "password for $ssid" -theme ~/.config/niri/rofi.rasi) || exit 0
nmcli dev wifi connect "$ssid" password "$pw" >/dev/null 2>&1 && notify-send -t 2500 "wifi" "connected: $ssid" || notify-send -t 3500 "wifi" "wrong password?"
