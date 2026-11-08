#!/usr/bin/env python3
"""Pomodoro for waybar: 25 min work, 5 min break. Quiet (no sound, short notice).
   pomodoro.py            -> JSON status
   pomodoro.py toggle     -> start / pause / resume
   pomodoro.py reset      -> back to idle
"""
import json, os, subprocess, sys, time

ST = os.path.expanduser("~/.cache/pomodoro.json")
WORK, BREAK = 25 * 60, 5 * 60


def load():
    try:
        return json.load(open(ST))
    except Exception:
        return {"phase": "idle"}


def save(s):
    os.makedirs(os.path.dirname(ST), exist_ok=True)
    json.dump(s, open(ST, "w"))


def note(title, body):
    subprocess.Popen(["notify-send", "-t", "4000", title, body], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def tick(s):
    """advance the phase when the timer ran out"""
    if s["phase"] in ("work", "break") and not s.get("paused") and time.time() >= s["end"]:
        if s["phase"] == "work":
            s = {"phase": "break", "end": time.time() + BREAK}
            note("pomodoro", "break: 5 minutes")
        else:
            s = {"phase": "idle"}
            note("pomodoro", "break over")
        save(s)
    return s


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    s = tick(load())
    if cmd == "toggle":
        if s["phase"] == "idle":
            s = {"phase": "work", "end": time.time() + WORK}
        elif s.get("paused"):
            s = {"phase": s["phase"], "end": time.time() + s["left"]}
        else:
            s = {"phase": s["phase"], "paused": True, "left": max(0, s["end"] - time.time())}
        save(s)
    elif cmd == "reset":
        s = {"phase": "idle"}
        save(s)
    if cmd != "status":
        subprocess.run(["pkill", "-RTMIN+10", "waybar"])
        return
    if s["phase"] == "idle":
        print(json.dumps({"text": "", "class": "idle", "tooltip": "pomodoro: click to start (25 min)"}))
        return
    left = int(s["left"] if s.get("paused") else max(0, s["end"] - time.time()))
    icon = "" if s.get("paused") else ("" if s["phase"] == "work" else "")
    cls = "paused" if s.get("paused") else s["phase"]
    print(json.dumps({"text": f"{icon}  {left // 60:02d}:{left % 60:02d}", "class": cls,
                      "tooltip": "click: pause/resume · right click: reset"}))


main()
