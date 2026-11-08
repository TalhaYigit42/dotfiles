#!/usr/bin/env bash
# Screenshot an area, draw on it (arrows, boxes, text) in satty, copy/save from there.
mkdir -p ~/Pictures/Screenshots
geo=$(slurp -d) || exit 0
grim -g "$geo" - | satty --filename - --output-filename ~/Pictures/Screenshots/annotated-$(date +%F_%H-%M-%S).png --copy-command wl-copy --early-exit
