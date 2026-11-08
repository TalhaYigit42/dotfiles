#!/usr/bin/env bash
# display-mode.sh extend|laptop|external|mirror   (niri has no built-in mirroring: wl-mirror is used for that)
mode="$1"
json=$(niri msg --json outputs)
lap=$(echo "$json" | jq -r 'keys[] | select(startswith("eDP"))' | head -1)
mapfile -t ext < <(echo "$json" | jq -r --arg l "$lap" 'keys[] | select(. != $l)')
[ ${#ext[@]} -eq 0 ] && { notify-send -t 3000 "monitor" "no second display connected"; exit 1; }
lw=$(echo "$json" | jq -r --arg l "$lap" '.[$l].logical.width // 1536')
place() { local x=$lw; for e in "${ext[@]}"; do niri msg output "$e" on; niri msg output "$e" position set "$x" 0; x=$((x + $(niri msg --json outputs | jq -r --arg e "$e" '.[$e].logical.width // 1920'))); done; }
case "$mode" in
  extend)   pkill -x wl-mirror; niri msg output "$lap" on; place ;;
  laptop)   pkill -x wl-mirror; niri msg output "$lap" on; for e in "${ext[@]}"; do niri msg output "$e" off; done ;;
  external) pkill -x wl-mirror; for e in "${ext[@]}"; do niri msg output "$e" on; done; niri msg output "$lap" off ;;
  mirror)   command -v wl-mirror >/dev/null || { notify-send -t 5000 "monitor" "Mirroring needs wl-mirror: sudo pacman -S wl-mirror"; exit 1; }
            niri msg output "$lap" on; place; pkill -x wl-mirror
            setsid wl-mirror --fullscreen-output "${ext[0]}" "$lap" >/dev/null 2>&1 & ;;
esac
