#!/usr/bin/env bash
# side.sh left|right : move sideways through columns; at the edge (or on an empty workspace)
# keep going into the previous/next workspace, so you can always keep going.
dir=$1
read -r cur last < <(python3 - <<'PY'
import json, subprocess
def j(*a): return json.loads(subprocess.check_output(["niri","msg","--json",*a]))
ws = next(w for w in j("workspaces") if w["is_focused"])
cols = [w["layout"]["pos_in_scrolling_layout"][0] for w in j("windows")
        if w["workspace_id"] == ws["id"] and w["layout"]["pos_in_scrolling_layout"]]
foc = next((w["layout"]["pos_in_scrolling_layout"][0] for w in j("windows")
            if w["is_focused"] and w["layout"]["pos_in_scrolling_layout"]), 0)
print(foc, max(cols, default=0))
PY
)
if [ "$dir" = right ]; then
  if [ "$cur" -gt 0 ] && [ "$cur" -lt "$last" ]; then niri msg action focus-column-right
  else niri msg action focus-workspace-down; fi
else
  if [ "$cur" -gt 1 ]; then niri msg action focus-column-left
  else niri msg action focus-workspace-up; fi
fi
