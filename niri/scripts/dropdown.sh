#!/usr/bin/env bash
# Dropdown terminal: toggles a floating kitty (cheap scratchpad substitute).
pkill -f 'kitty --class dropdown' || exec kitty --class dropdown
