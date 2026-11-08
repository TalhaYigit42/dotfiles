#!/usr/bin/env python3
"""Audio state: outputs, inputs, per-app streams (JSON)."""
import json, subprocess
def pa(*a):
    try: return json.loads(subprocess.run(["pactl", "--format=json", *a], capture_output=True, text=True, timeout=5).stdout or "[]")
    except Exception: return []
def vol(o):
    v = o.get("volume") or {}
    for ch in v.values(): return int(str(ch.get("value_percent", "0%")).strip("%"))
    return 0
ds = subprocess.run(["pactl", "get-default-sink"], capture_output=True, text=True).stdout.strip()
dsrc = subprocess.run(["pactl", "get-default-source"], capture_output=True, text=True).stdout.strip()
out = {"sinks": [], "sources": [], "apps": []}
for s in pa("list", "sinks"):
    p = s.get("properties", {})
    out["sinks"].append({"name": s["name"], "desc": s.get("description", s["name"]), "vol": vol(s), "mute": s.get("mute", False),
                         "default": s["name"] == ds, "bus": p.get("device.bus", ""), "state": s.get("state", "")})
for s in pa("list", "sources"):
    if s["name"].endswith(".monitor"): continue
    out["sources"].append({"name": s["name"], "desc": s.get("description", s["name"]), "vol": vol(s), "mute": s.get("mute", False), "default": s["name"] == dsrc})
for i in pa("list", "sink-inputs"):
    p = i.get("properties", {})
    out["apps"].append({"id": i["index"], "name": p.get("application.name") or p.get("media.name") or "?", "vol": vol(i), "mute": i.get("mute", False)})
print(json.dumps(out))
