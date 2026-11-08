#!/usr/bin/env bash
# Toggle screen recording (wf-recorder, wlr-screencopy). Mod+Shift+S = region, stop with same key.
if pidof wf-recorder >/dev/null; then pkill -INT wf-recorder; notify-send "󰑋  Recording saved" "~/Videos"; exit; fi
mkdir -p ~/Videos
geo=$(slurp) || exit 1
notify-send "󰑋  Recording started"
exec wf-recorder -g "$geo" -f ~/Videos/rec-$(date +%F_%H-%M-%S).mp4
