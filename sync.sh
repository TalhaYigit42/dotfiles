#!/usr/bin/env bash
# Maintainer helper: copy the live config from ~/.config back into this repo and strip personal paths.
# (Not needed for installing -- use install.sh for that.)
set -euo pipefail
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; C="${XDG_CONFIG_HOME:-$HOME/.config}"
cd "$D"
cp "$C"/niri/{config.kdl,glitch.kdl,rofi.rasi,hyprlock.conf,swaylock.conf,snippets.txt} niri/
cp "$C"/niri/waybar/{config.jsonc,style.css} niri/waybar/
for f in "$C"/niri/scripts/*; do case "$f" in *.bak|*.bak[0-9]|*.pyc|*/untis.py) ;; *) [ -f "$f" ] && cp "$f" niri/scripts/;; esac; done
cp "$C"/quickshell/sidebar/*.qml quickshell/sidebar/
cp "$C"/swaync/{config.json,style.css} swaync/
cp "$C"/starship.toml starship/starship.toml
cp "$C"/cava/config cava/config 2>/dev/null || true
cp "$C"/fastfetch/lain-*.txt fastfetch/
sed '/^include hyde.conf/d' "$C"/kitty/kitty.conf > kitty/kitty.conf
# machine-specific bits -> placeholders (install.sh puts them back)
grep -rIl "$HOME" . 2>/dev/null | grep -v -E '^\./(\.git|README|sync.sh)' | xargs -r sed -i "s|$HOME|@HOME@|g"
sed -i '/#custom-untis/d' niri/waybar/style.css
sed -i '/"custom\/untis"/d' niri/waybar/config.jsonc
sed -i 's|@HOME@/.config/hyde/themes/Mainy/wallpapers|@HOME@/Pictures/Wallpapers|g; s|\$HOME/.config/hyde/themes/Mainy/wallpapers/rei1.jpg|$HOME/Pictures/Wallpapers/lock.jpg|' niri/hyprlock.conf
# neutral wallpaper locations (the live system uses a HyDE theme folder)
sed -i 's|\$HOME/.config/hyde/themes/Mainy/wallpapers/rei1.jpg|$HOME/Pictures/Wallpapers/lock.jpg|' niri/hyprlock.conf
sed -i 's|root.home + "/.config/hyde/themes/Mainy/wallpapers"|root.home + "/Pictures/Wallpapers"|' quickshell/sidebar/shell.qml
sed -i "s|find \"\$HOME/.config/hyde/themes\" -path '\*/wallpapers/\*' -type f|find \"\$HOME/Pictures/Wallpapers\" -type f|" niri/scripts/wallpaper.sh
sed -i 's|\$HOME/.config/niri/wallpaper.png|$HOME/Pictures/Wallpapers/lock.jpg|' niri/scripts/lock.sh
echo "synced."
