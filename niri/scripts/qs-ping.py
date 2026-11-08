#!/usr/bin/env python3
"""Latency + packet loss to the internet and to the gateway (JSON)."""
import json, re, subprocess
def ping(host, n=4):
    try:
        o = subprocess.run(["ping", "-c", str(n), "-i", "0.25", "-W", "1", "-q", host], capture_output=True, text=True, timeout=8).stdout
    except Exception: return {"ms": None, "loss": 100}
    loss = re.search(r"([\d.]+)% packet loss", o); rtt = re.search(r"= [\d.]+/([\d.]+)/", o)
    return {"ms": float(rtt.group(1)) if rtt else None, "loss": float(loss.group(1)) if loss else 100}
gw = ""
r = subprocess.run(["ip", "-4", "route", "show", "default"], capture_output=True, text=True).stdout.split()
if "via" in r: gw = r[r.index("via") + 1]
print(json.dumps({"net": ping("1.1.1.1"), "gw": ping(gw, 3) if gw else {"ms": None, "loss": 100}}))
