#!/usr/bin/env python3
"""Streams one JSON line per second: cpu %, ram %, net rx/tx bytes/s, temperature. (for the graphs)"""
import json, sys, time, glob
def cpu():
    p = open("/proc/stat").readline().split()[1:]; v = list(map(int, p)); return sum(v), v[3] + v[4]
def mem():
    m = {}
    for l in open("/proc/meminfo"):
        k, v = l.split(":"); m[k] = int(v.split()[0])
        if len(m) > 6: break
    t = m["MemTotal"]; a = m["MemAvailable"]; return t, t - a
def net():
    rx = tx = 0
    for l in open("/proc/net/dev").readlines()[2:]:
        n, d = l.split(":"); n = n.strip()
        if n == "lo" or n.startswith(("virbr", "docker", "veth")): continue
        f = d.split(); rx += int(f[0]); tx += int(f[8])
    return rx, tx
def temp():
    best = 0
    for z in glob.glob("/sys/class/thermal/thermal_zone*"):
        try:
            if open(z + "/type").read().strip() in ("x86_pkg_temp", "acpitz"): best = max(best, int(open(z + "/temp").read()) / 1000)
        except Exception: pass
    return best
pt, pi = cpu(); pr, ptx = net()
while True:
    time.sleep(1)
    t, i = cpu(); r, x = net(); mt, mu = mem()
    dt = t - pt; c = 100 * (1 - (i - pi) / dt) if dt else 0
    print(json.dumps({"cpu": round(c, 1), "ram": round(100 * mu / mt, 1), "ram_used": round(mu / 1048576, 2), "ram_total": round(mt / 1048576, 2),
                      "rx": r - pr, "tx": x - ptx, "temp": round(temp())}), flush=True)
    pt, pi, pr, ptx = t, i, r, x
