#!/usr/bin/env bash
# Project switcher: pick a repo/folder -> VS Code + a terminal in it.
# usage: projects.sh            (rofi)    projects.sh --list   (print candidates)
list() {
  { for root in "$HOME/GitHub" "$HOME/Projects" "$HOME/dev"; do   # add your own roots here
      [ -d "$root" ] || continue
      find "$root" -maxdepth 2 -name .git -type d -printf '%h\n' 2>/dev/null
    done
    ls -d "$HOME"/Projects/*/ 2>/dev/null | sed 's#/$##'
  } | sort -u
}
[ "$1" = "--list" ] && { list; exit; }
sel=$(list | sed "s#^$HOME#~#" | rofi -dmenu -i -p "project" -theme ~/.config/niri/rofi.rasi) || exit 0
dir="${sel/#\~/$HOME}"; [ -d "$dir" ] || exit 0
setsid code "$dir" >/dev/null 2>&1 &
setsid kitty -d "$dir" >/dev/null 2>&1 &
