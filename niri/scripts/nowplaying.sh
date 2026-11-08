#!/usr/bin/env bash
# Spotify line for the lock screen (empty when nothing plays)
s=$(playerctl -p spotify status 2>/dev/null) || exit 0
[ "$s" = Playing ] || [ "$s" = Paused ] || exit 0
printf '%s  %s' "$([ "$s" = Playing ] && echo '' || echo '')" "$(playerctl -p spotify metadata --format '{{artist}} — {{title}}' 2>/dev/null | cut -c1-60)"
