#!/usr/bin/env bash
# NAVI: Lain's machine never sleeps. ON = no auto-lock, no screen-off, no suspend.
# usage: navi.sh toggle | status | start-idle
S="$HOME/.config/niri/scripts"
start_idle() {
  exec swayidle -w \
    timeout 240 "$S/lock.sh" \
    timeout 360 "niri msg action power-off-monitors" resume "niri msg action power-on-monitors" \
    timeout 900 "pidof hyprlock swaylock >/dev/null && systemctl suspend" \
    before-sleep "$S/lock.sh"
}
active() { ! pgrep -x swayidle >/dev/null; }   # navi is awake when the idle daemon is stopped
case "$1" in
  start-idle) start_idle ;;
  toggle)
    if active; then
      (setsid "$0" start-idle >/dev/null 2>&1 &)
    else
      pkill -x swayidle
    fi
    pkill -RTMIN+9 waybar ;;
  status|*)
    if active; then printf '{"text":"\\uf06e  navi","class":"on","tooltip":"Navi online: no auto-lock or sleep\\nclick for standby"}\n'
    else printf '{"text":"\\uf070","class":"off","tooltip":"Navi standby (auto-lock active)\\nclick or Super+I to keep awake"}\n'; fi ;;
esac
