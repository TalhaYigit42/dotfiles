#!/usr/bin/env python3
"""Un-maximize windows that open edge-to-edge (apps like Blender/Spotify remember 'maximized').
Only acts on NEW windows, once, within 8 s of opening, so Super+F etc. keep working."""
import json, subprocess, time

def run(*a):
    return subprocess.run(["niri", "msg", *a], capture_output=True, text=True).stdout

def work_area():
    # full-width tile + full-height tile == maximized to edges; compute from the output
    o = json.loads(run("--json", "outputs"))
    out = next(iter(o.values()))
    return out["logical"]["width"], out["logical"]["height"]

seen = {}     # id -> first-seen time
fixed = set()
W, H = work_area()
BAR = 48      # waybar exclusive zone (logical px)

def check(w):
    if w.get("is_floating"):
        return
    t = w["layout"].get("tile_size")
    if not t:
        return
    if t[0] >= W - 2 and t[1] >= H - BAR - 4 and t[1] < H - 4:
        subprocess.run(["niri", "msg", "action", "maximize-window-to-edges", "--id", str(w["id"])])
        fixed.add(w["id"])

p = subprocess.Popen(["niri", "msg", "--json", "event-stream"], stdout=subprocess.PIPE, text=True)
for line in p.stdout:
    try:
        ev = json.loads(line)
    except Exception:
        continue
    wins = []
    if "WindowsChanged" in ev:
        wins = ev["WindowsChanged"]["windows"]
        for w in wins:
            seen.setdefault(w["id"], 0)          # pre-existing windows: never touched
    elif "WindowOpenedOrChanged" in ev:
        w = ev["WindowOpenedOrChanged"]["window"]
        if w["id"] not in seen:
            seen[w["id"]] = time.time()
        wins = [w]
    elif "WindowLayoutsChanged" in ev:
        ids = {i for i, _ in ev["WindowLayoutsChanged"]["changes"]}
        wins = [w for w in json.loads(run("--json", "windows")) if w["id"] in ids]
    for w in wins:
        t0 = seen.get(w["id"], 0)
        if t0 and w["id"] not in fixed and time.time() - t0 < 8:
            check(w)
