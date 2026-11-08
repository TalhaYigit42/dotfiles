#!/usr/bin/env bash
# Waybar module: "WS 01 · COL 2/3" = workspace 1, column 2 of 3 (focused workspace).
python3 - <<'PY'
import json, subprocess
def j(*a): return json.loads(subprocess.check_output(["niri","msg","--json",*a]))
try:
    ws = j("workspaces"); wins = j("windows")
    f = next(w for w in ws if w["is_focused"])
    cols = {w["layout"]["pos_in_scrolling_layout"][0] for w in wins if w["workspace_id"] == f["id"] and w["layout"]["pos_in_scrolling_layout"]}
    cur = next((w["layout"]["pos_in_scrolling_layout"][0] for w in wins if w["is_focused"] and w["layout"]["pos_in_scrolling_layout"]), 0)
    tip = f"Workspace {f['idx']}\nColumn {cur} of {len(cols)}"
    print(json.dumps({"text": f"{f['idx']}  ·  {cur}/{len(cols)}", "tooltip": tip}))
except Exception:
    print(json.dumps({"text": "WS --"}))
PY
