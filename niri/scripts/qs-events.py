#!/usr/bin/env python3
"""Events from ~/.config/niri/events.txt  ("2026-11-12 14:30 Dentist" per line).  events.py            -> JSON
   qs-events.py add "tomorrow 14:30 Dentist"  -> append (also: today, 12.11., 12.11.2026, 2026-11-12)"""
import json, os, re, sys
from datetime import date, datetime, timedelta
F = os.path.expanduser("~/.config/niri/events.txt")
def parse_day(tok):
    t = tok.lower(); today = date.today()
    if t in ("heute", "today"): return today
    if t in ("morgen", "tomorrow"): return today + timedelta(days=1)
    if t in ("übermorgen", "uebermorgen", "overmorrow"): return today + timedelta(days=2)
    m = re.fullmatch(r"(\d{4})-(\d{2})-(\d{2})", t)
    if m: return date(*map(int, m.groups()))
    m = re.fullmatch(r"(\d{1,2})\.(\d{1,2})\.?(\d{4})?", t)
    if m:
        y = int(m.group(3) or today.year); d = date(y, int(m.group(2)), int(m.group(1)))
        if not m.group(3) and d < today: d = date(y + 1, d.month, d.day)
        return d
    return None
if len(sys.argv) > 2 and sys.argv[1] == "add":
    p = sys.argv[2].split(None, 2)
    if len(p) < 2: sys.exit(1)
    d = parse_day(p[0])
    if not d: sys.exit(2)
    tm, title = "", ""
    rest = " ".join(p[1:])
    m = re.match(r"(\d{1,2}):(\d{2})\s+(.*)", rest)
    if m: tm, title = f"{int(m.group(1)):02d}:{m.group(2)}", m.group(3)
    else: title = rest
    open(F, "a").write(f"{d.isoformat()} {tm or '--:--'} {title}\n"); sys.exit(0)
ev = []
try:
    for l in open(F, encoding="utf-8"):
        m = re.match(r"(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}|--:--)\s+(.*)", l.strip())
        if m: ev.append({"date": m.group(1), "time": "" if m.group(2) == "--:--" else m.group(2), "title": m.group(3)})
except OSError: pass
ev.sort(key=lambda e: (e["date"], e["time"]))
print(json.dumps(ev))
