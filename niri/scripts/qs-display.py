#!/usr/bin/env python3
"""Outputs from niri (JSON list)."""
import json, subprocess
d = json.loads(subprocess.run(["niri", "msg", "--json", "outputs"], capture_output=True, text=True).stdout or "{}")
res = []
for name, o in d.items():
    seen, modes = set(), []
    for i, m in enumerate(o.get("modes", [])):
        k = f"{m['width']}x{m['height']}@{m['refresh_rate']/1000:.3f}"
        if k in seen: continue
        seen.add(k); modes.append({"s": k, "label": f"{m['width']}×{m['height']} · {round(m['refresh_rate']/1000)} Hz", "cur": i == o.get("current_mode")})
    lg = o.get("logical") or {}
    res.append({"name": name, "model": f"{o.get('make','')} {o.get('model','')}".strip(), "on": bool(lg), "x": lg.get("x", 0), "y": lg.get("y", 0),
                "w": lg.get("width", 0), "h": lg.get("height", 0), "scale": lg.get("scale", 1), "transform": lg.get("transform", "Normal"),
                "vrr": o.get("vrr_enabled", False), "modes": modes[:12]})
print(json.dumps(res))
