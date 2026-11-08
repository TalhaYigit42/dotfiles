#!/usr/bin/env bash
# Turn the Lain glitch animations on/off by (un)commenting the include line in config.kdl.
C="$HOME/.config/niri/config.kdl"
if grep -q '^include "glitch.kdl"' "$C"; then sed -i 's|^include "glitch.kdl"|// include "glitch.kdl"|' "$C"
else sed -i 's|^// include "glitch.kdl"|include "glitch.kdl"|' "$C"; fi
