#!/usr/bin/env bash
# Chess menu: Stockfish in 4 strengths, 2 players, Lichess (if you saved a token), daily puzzle in the browser.
# All terminal games run silent (--no-sound).
T="$HOME/.config/niri/lichess.token"
menu="Stockfish · easy\nStockfish · medium\nStockfish · hard\nStockfish · full strength\n2 players (one computer)\nDaily puzzle (browser)"
[ -f "$T" ] && menu="$menu\nLichess online"
c=$(printf "$menu" | rofi -dmenu -i -p "chess" -theme ~/.config/niri/rofi.rasi) || exit 0
run() { setsid kitty --class chess -o confirm_os_window_close=0 -e chess-tui --no-sound "$@" >/dev/null 2>&1 & }
case "$c" in
  *easy*)  run -e /usr/bin/stockfish --difficulty easy ;;
  *medium*)  run -e /usr/bin/stockfish --difficulty medium ;;
  *hard*)   run -e /usr/bin/stockfish --difficulty hard ;;
  *full*)   run -e /usr/bin/stockfish ;;
  *players*) run ;;
  *puzzle*) xdg-open https://lichess.org/training/daily >/dev/null 2>&1 ;;
  *Lichess*) run -l "$(cat "$T")" ;;
esac
