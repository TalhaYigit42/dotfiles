#!/usr/bin/env bash
choice=$(printf '  Layer 01 (lock)\n󰍃  Leave the Wired (logout)\n󰒲  Sleep\n  Open the next (reboot)\n  Close the world (shutdown)' | rofi -dmenu -i -p "protocol 7" -theme ~/.config/niri/rofi.rasi)
case "$choice" in
  *"Layer 01"*) ~/.config/niri/scripts/lock.sh ;;
  *"Leave the Wired"*) niri msg action quit ;;
  *Sleep*) systemctl suspend ;;
  *"Open the next"*) systemctl reboot ;;
  *"Close the world"*) systemctl poweroff ;;
esac
