#!/usr/bin/env bash
# Installs these dotfiles into $HOME. Existing files are moved to a timestamped backup folder first.
# It never uses sudo. Packages are listed in README.md.
set -euo pipefail
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BK="$HOME/.dotfiles-backup-$(date +%F_%H%M%S)"

put() {  # put <source relative to repo> <destination>
  local src="$SRC/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] || [ -L "$dst" ]; then mkdir -p "$BK/$(dirname "${dst#$HOME/}")"; mv "$dst" "$BK/${dst#$HOME/}"; fi
  cp -a "$src" "$dst"
}

echo "Installing into $CFG (backup of replaced files: $BK)"
put niri "$CFG/niri"
put quickshell/sidebar "$CFG/quickshell/sidebar"
put swaync "$CFG/swaync"
put starship/starship.toml "$CFG/starship.toml"
put cava/config "$CFG/cava/config"
put kitty/kitty.conf "$CFG/kitty/kitty.conf"
put zsh/dotfiles.zsh "$CFG/zsh/dotfiles.zsh"
mkdir -p "$CFG/fastfetch"; cp -a "$SRC"/fastfetch/lain-*.txt "$CFG/fastfetch/"
put applications/spotify.desktop "$HOME/.local/share/applications/spotify.desktop"

# fill in the home directory (the repo contains the placeholder @HOME@ in a few absolute paths)
grep -rIl '@HOME@' "$CFG/niri" "$CFG/swaync" 2>/dev/null | xargs -r sed -i "s|@HOME@|$HOME|g"
sed -i "s|@HOME@|$HOME|g" "$HOME/.local/share/applications/spotify.desktop" 2>/dev/null || true

chmod +x "$CFG"/niri/scripts/* 2>/dev/null || true
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"

echo
echo "Done. Next:"
echo "  1. Put wallpapers in ~/Pictures/Wallpapers (and a lock screen image named lock.jpg there)."
echo "  2. Add this line to your ~/.zshrc:   source ~/.config/zsh/dotfiles.zsh"
echo "  3. Check the keyboard layout in ~/.config/niri/config.kdl (input -> xkb -> layout)."
echo "  4. Log out and pick 'niri' in your display manager."
