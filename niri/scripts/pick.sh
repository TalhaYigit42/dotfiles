#!/usr/bin/env bash
# Numbered window picker: "workspace.column  title". Pick one to jump to it.
choice=$(python3 - <<'PY'
import json, subprocess
def j(*a): return json.loads(subprocess.check_output(["niri","msg","--json",*a]))
ws = {w["id"]: w["idx"] for w in j("workspaces")}
rows = []
for w in j("windows"):
    p = w["layout"]["pos_in_scrolling_layout"]
    col = p[0] if p else "float"
    rows.append((ws.get(w["workspace_id"], 0), col if p else 99, w["id"], f"{ws.get(w['workspace_id'],'?')}.{col}   {w['app_id'] or ''}  —  {w['title']}"))
for r in sorted(rows, key=lambda r: (r[0], r[1])):
    print(f"{r[3]}\t{r[2]}")
PY
)
[ -z "$choice" ] && exit 0
sel=$(printf '%s\n' "$choice" | cut -f1 | rofi -dmenu -i -p "windows" -theme "$HOME/.config/niri/rofi.rasi" -format i) || exit 0
id=$(printf '%s\n' "$choice" | sed -n "$((sel+1))p" | cut -f2)
niri msg action focus-window --id "$id"
