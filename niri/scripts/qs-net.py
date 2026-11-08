#!/usr/bin/env python3
"""Network overview: active connections, wifi list, link details (JSON). Ping is measured by qs-ping.py."""
import json, subprocess, re
def sh(*a, t=8):
    try: return subprocess.run(a, capture_output=True, text=True, timeout=t).stdout
    except Exception: return ""
def split(l): return re.split(r"(?<!\\):", l)
out = {"active": [], "wifi": [], "ip": "", "gw": "", "dev": "", "rx": 0, "tx": 0}
for l in sh("nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "con", "show", "--active").splitlines():
    n, t, d = (split(l) + ["", "", ""])[:3]
    if t == "loopback" or d == "lo": continue
    out["active"].append({"name": n.replace("\\:", ":"), "type": t.replace("802-11-wireless", "wifi").replace("802-3-ethernet", "ethernet"), "dev": d})
seen = {}
for l in sh("nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY,RATE,BSSID", "dev", "wifi", "list").splitlines():
    p = split(l)
    if len(p) < 5: continue
    inuse, ssid, sig, sec, rate = p[0] == "*", p[1].replace("\\:", ":"), int(p[2] or 0), p[3], p[4]
    if not ssid: continue
    e = {"ssid": ssid, "signal": sig, "sec": sec or "offen", "rate": rate, "inuse": inuse}
    if ssid not in seen or inuse or (not seen[ssid]["inuse"] and sig > seen[ssid]["signal"]): seen[ssid] = e
out["wifi"] = sorted(seen.values(), key=lambda e: (not e["inuse"], -e["signal"]))
route = sh("ip", "-4", "route", "show", "default").split()
if "via" in route: out["gw"] = route[route.index("via") + 1]
if "dev" in route: out["dev"] = route[route.index("dev") + 1]
if out["dev"]:
    m = re.search(r"inet (\S+)", sh("ip", "-4", "-o", "addr", "show", out["dev"]))
    out["ip"] = m.group(1) if m else ""
    try:
        out["rx"] = int(open(f"/sys/class/net/{out['dev']}/statistics/rx_bytes").read()); out["tx"] = int(open(f"/sys/class/net/{out['dev']}/statistics/tx_bytes").read())
    except Exception: pass
print(json.dumps(out))
