#!/usr/bin/env python3
"""Quick status for the Home tab (one JSON object)."""
import json, subprocess, os, re
def sh(*a, t=4):
    try: return subprocess.run(a, capture_output=True, text=True, timeout=t).stdout.strip()
    except Exception: return ""
d = {}
d["wifi_on"] = sh("nmcli", "radio", "wifi") == "enabled"
act = sh("nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL", "dev", "wifi")
ssid, sig = "", 0
for l in act.splitlines():
    p = l.split(":")
    if p and p[0] == "yes": ssid, sig = ":".join(p[1:-1]), int(p[-1] or 0); break
d["ssid"], d["signal"] = ssid, sig
bt = sh("bluetoothctl", "show")
d["bt_on"] = "Powered: yes" in bt
d["bt_devs"] = [l.split(" ", 2)[2] for l in sh("bluetoothctl", "devices", "Connected").splitlines() if l.count(" ") >= 2]
d["dnd"] = sh("swaync-client", "-D") == "true"
d["night"] = subprocess.run(["pgrep", "-x", "wlsunset"], capture_output=True).returncode == 0
d["navi"] = subprocess.run(["pgrep", "-x", "swayidle"], capture_output=True).returncode != 0
try:
    b = "/sys/class/power_supply/BAT0/"
    d["bat"] = int(open(b + "capacity").read()); d["bat_status"] = open(b + "status").read().strip()
except Exception: d["bat"], d["bat_status"] = -1, ""
v = sh("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@")
m = re.search(r"([0-9.]+)", v); d["vol"] = float(m.group(1)) if m else 0; d["muted"] = "MUTED" in v
try: d["bri"] = int(sh("brightnessctl", "-m").split(",")[3].strip("%")) / 100
except Exception: d["bri"] = 0
print(json.dumps(d))
