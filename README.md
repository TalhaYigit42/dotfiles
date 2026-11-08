# dotfiles

hyprland sucks and keeps crashing after every system update (`pacman -Syu`) or hyprland update, so i switched to **niri** in hope it's more stable. here are my dotfiles for anyone who likes the looks.

aesthetically it's inspired by my fav shows, evangelion and lain, just subtle tho lol. enjoy.

## includes

- **waybar** top bar (clock, workspace/column readout, spotify, keep-awake toggle, system stats)
- **quickshell sidebar** (`Super+Space`) with tabs: home, apps, wallpapers, tools, audio, internet, monitor, task manager with live graphs, weather, calendar, dev projects
- **now-playing card** (`Super+M`) and a volume/brightness OSD
- **hyprlock** lock screen, **rofi** launcher, **swaync** notification center, **starship** prompt
- little scripts: ocr, annotated screenshots, project switcher, snippets, calculator, chess menu (stockfish + lichess daily puzzle)
- optional glitch window animations (`Super+Shift+G`)

some widget text is in german, sorry.

## install

```bash
git clone <this repo> ~/dotfiles && cd ~/dotfiles
./install.sh   # backs up what it replaces, no sudo
```

then put wallpapers in `~/Pictures/Wallpapers` (a `lock.jpg` there is used for the lock screen) and add `source ~/.config/zsh/dotfiles.zsh` to your `~/.zshrc`. the keyboard layout is set to `de` in `niri/config.kdl`, change it.

## packages (arch)

`niri xwayland-satellite waybar quickshell rofi swaync swayidle hyprlock awww kitty jq python playerctl brightnessctl wl-clipboard cliphist grim slurp networkmanager bluez`

optional: `satty wf-recorder wlsunset tesseract kdeconnect cava fastfetch starship zoxide eza bat fzf lazygit chess-tui stockfish` and CaskaydiaCove Nerd Font.

wallpapers aren't included. the lain ascii logos in `fastfetch/` are from around the internet, author unknown.
