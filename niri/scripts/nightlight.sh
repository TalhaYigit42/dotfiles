#!/usr/bin/env bash
# Toggle warm night light (wlsunset, fixed 4000 K). Bar shows it via signal.
if ! command -v wlsunset >/dev/null; then notify-send -t 4000 "night light" "wlsunset missing: sudo pacman -S wlsunset"; exit 1; fi
if pgrep -x wlsunset >/dev/null; then pkill -x wlsunset; else setsid wlsunset -t 4000 -T 4001 >/dev/null 2>&1 & fi
