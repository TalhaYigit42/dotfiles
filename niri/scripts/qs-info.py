#!/usr/bin/env python3
"""Static specs (JSON)."""
import json, subprocess, platform, os, re, shutil
def sh(*a):
    try: return subprocess.run(a, capture_output=True, text=True, timeout=5).stdout.strip()
    except Exception: return ""
cpu = re.search(r"model name\s*:\s*(.*)", open("/proc/cpuinfo").read()).group(1)
cpu = re.sub(r"\(R\)|\(TM\)| CPU|@.*", "", cpu).strip()
gpu = ""
for l in sh("lspci").splitlines():
    if "VGA" in l or "3D" in l or "Display" in l: gpu = l.split(": ", 1)[-1]; break
gpu = re.sub(r"\[.*?\]|\(rev.*?\)|Corporation|Intel", "", gpu).strip() or "?"
mem = int(re.search(r"MemTotal:\s+(\d+)", open("/proc/meminfo").read()).group(1)) / 1048576
du = shutil.disk_usage("/")
up = float(open("/proc/uptime").read().split()[0])
print(json.dumps({"cpu": cpu, "cores": os.cpu_count(), "gpu": gpu, "ram": f"{mem:.1f} GB", "disk": f"{du.used/1e9:.0f} / {du.total/1e9:.0f} GB",
                  "disk_pct": round(100 * du.used / du.total), "kernel": platform.release(), "uptime": f"{int(up//3600)} h {int(up%3600//60)} min", "host": platform.node()}))
