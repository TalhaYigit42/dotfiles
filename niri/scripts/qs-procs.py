#!/usr/bin/env python3
"""Top processes by CPU (JSON)."""
import json, subprocess
o = subprocess.run(["ps", "-eo", "pid=,%cpu=,%mem=,rss=,comm=", "--sort=-%cpu"], capture_output=True, text=True).stdout.splitlines()
res = []
for l in o:
    p = l.split(None, 4)
    if len(p) < 5 or p[4] in ("ps", "python3", "qs", "quickshell"): continue
    res.append({"pid": int(p[0]), "name": p[4], "cpu": float(p[1]), "mem": float(p[2]), "mb": round(int(p[3]) / 1024)})
    if len(res) >= 7: break
print(json.dumps(res))
