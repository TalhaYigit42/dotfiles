#!/usr/bin/env python3
"""KDE Connect phone status for waybar: battery of the first reachable paired phone.
Hidden when KDE Connect is missing or no phone is reachable."""
import json, shutil, subprocess

def run(*a):
    return subprocess.run(a, capture_output=True, text=True, timeout=8).stdout.strip()

def prop(dev, name):
    out = run("busctl", "--user", "--json=short", "get-property", "org.kde.kdeconnect",
              f"/modules/kdeconnect/devices/{dev}/battery", "org.kde.kdeconnect.device.battery", name)
    try:
        return json.loads(out)["data"]
    except Exception:
        return None

def main():
    if not shutil.which("kdeconnect-cli"):
        print(json.dumps({"text": "", "class": "none"})); return
    try:
        import re
        lines = [l for l in run("kdeconnect-cli", "-a", "--id-name-only").splitlines() if re.match(r"^[0-9a-f_-]{8,} ", l)]
    except Exception:
        lines = []
    if not lines:
        print(json.dumps({"text": "", "class": "none"})); return
    dev, _, name = lines[0].partition(" ")
    ch, charging = prop(dev, "charge"), prop(dev, "isCharging")
    if ch is None or ch < 0:
        print(json.dumps({"text": "", "class": "phone", "tooltip": f"{name}\nconnected · click: menu"})); return
    icon = "" if charging else ""
    cls = "charging" if charging else ("low" if ch <= 20 else "phone")
    print(json.dumps({"text": f"{icon}  {ch}%", "class": cls,
                      "tooltip": f"{name}\nBattery {ch}%{' (charging)' if charging else ''}\nclick: phone menu"}))

main()
