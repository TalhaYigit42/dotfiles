#!/usr/bin/env bash
# Phone menu (KDE Connect): ring, send clipboard/screenshot/file, open phone files. Needs: kdeconnect (+ sshfs for files).
msg() { printf '%s\n' "$@" | rofi -dmenu -p "phone" -theme ~/.config/niri/rofi.rasi >/dev/null; }
command -v kdeconnect-cli >/dev/null || { msg "kdeconnect is missing" "sudo pacman -S kdeconnect sshfs"; exit 1; }
mapfile -t devs < <(kdeconnect-cli -a --id-name-only 2>/dev/null | grep -E "^[0-9a-f_-]{8,} ")
if [ ${#devs[@]} -eq 0 ]; then
  paired=$(kdeconnect-cli -l 2>/dev/null | grep -i paired | sed 's/^- \([^:]*\):.*/\1/' | head -1)
  if [ -n "$paired" ]; then msg "$paired is not reachable right now" "Open KDE Connect on the phone" "and be on the same Wi-Fi"
  else msg "No phone paired" "Open KDE Connect on the phone," "pick this laptop and pair"; fi
  exit 1
fi
if [ ${#devs[@]} -gt 1 ]; then pick=$(printf '%s\n' "${devs[@]#* }" | rofi -dmenu -i -p "phone" -theme ~/.config/niri/rofi.rasi) || exit 0
  line=$(printf '%s\n' "${devs[@]}" | grep -F " $pick" | head -1); else line="${devs[0]}"; fi
id=${line%% *}; name=${line#* }
c=$(printf '%s\n' "Ring phone" "Send clipboard text" "Send last screenshot" "Send a file" "Open phone files" "Ping" | rofi -dmenu -i -p "$name" -theme ~/.config/niri/rofi.rasi) || exit 0
case "$c" in
  *"Ring phone"*) kdeconnect-cli -d "$id" --ring ;;
  *"clipboard text"*) kdeconnect-cli -d "$id" --share-text "$(wl-paste -n)" && notify-send -t 2000 "phone" "text sent" ;;
  *"last screenshot"*) f=$(ls -t ~/Pictures/Screenshots/* 2>/dev/null | head -1); [ -n "$f" ] && kdeconnect-cli -d "$id" --share "$f" && notify-send -t 2000 "phone" "screenshot sent" ;;
  *"Send a file"*) f=$(zenity --file-selection --title="Send file to $name") && kdeconnect-cli -d "$id" --share "$f" && notify-send -t 2000 "phone" "file sent" ;;
  *"phone files"*) command -v sshfs >/dev/null || { notify-send -t 4000 "phone" "sshfs missing: sudo pacman -S sshfs"; exit 1; }
     busctl --user call org.kde.kdeconnect "/modules/kdeconnect/devices/$id/sftp" org.kde.kdeconnect.device.sftp mountAndWait >/dev/null 2>&1
     mp=$(busctl --user --json=short call org.kde.kdeconnect "/modules/kdeconnect/devices/$id/sftp" org.kde.kdeconnect.device.sftp getMountPoint 2>/dev/null | python3 -c "import sys,json;print(json.load(sys.stdin)['data'][0])" 2>/dev/null)
     [ -n "$mp" ] && setsid thunar "$mp" >/dev/null 2>&1 & ;;
  *Ping*) kdeconnect-cli -d "$id" --ping ;;
esac
