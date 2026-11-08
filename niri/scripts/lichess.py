#!/usr/bin/env python3
"""Lichess for waybar: daily puzzle (+ your ratings if ~/.config/niri/lichess.user holds your username).
Uses only the public API, no token. Cached, works offline with the last data."""
import json, os, sys, time, urllib.request

H = os.path.expanduser("~")
CACHE = H + "/.cache/lichess.json"
USERF = H + "/.config/niri/lichess.user"


def get(url, key, max_age):
    c = {}
    try:
        c = json.load(open(CACHE))
    except Exception:
        pass
    e = c.get(key)
    if e and time.time() - e["t"] < max_age:
        return e["d"]
    try:
        d = json.load(urllib.request.urlopen(urllib.request.Request(url, headers={"User-Agent": "niri-waybar"}), timeout=8))
        c[key] = {"t": time.time(), "d": d}
        os.makedirs(os.path.dirname(CACHE), exist_ok=True)
        json.dump(c, open(CACHE, "w"))
        return d
    except Exception:
        return e["d"] if e else None


def main():
    puz = get("https://lichess.org/api/puzzle/daily", "daily", 3600)
    user = ""
    try:
        user = open(USERF).read().strip()
    except OSError:
        pass
    lines, text = [], None
    if puz:
        p = puz["puzzle"]
        lines.append(f"Daily puzzle {p['id']} · rating {p['rating']} · {p['plays']:,} plays")
        lines.append("Themes: " + ", ".join(p.get("themes", [])[:4]))
        text = f"♞ {p['rating']}"
    if user:
        u = get(f"https://lichess.org/api/user/{user}", "user", 900)
        if u and "perfs" in u:
            pf = u["perfs"]
            names = {"bullet": "Bullet", "blitz": "Blitz", "rapid": "Rapid", "classical": "Classical", "puzzle": "Puzzles"}
            lines.append("")
            lines.append(f"{u.get('username', user)}:")
            for k, n in names.items():
                if k in pf and pf[k].get("games", 0) > 0 or k == "puzzle" and k in pf:
                    lines.append(f"  {n}: {pf[k]['rating']}")
            best = next((pf[k]["rating"] for k in ("rapid", "blitz", "bullet") if k in pf and pf[k].get("games", 0) > 0), None)
            if best:
                text = f"♞ {best}"
    if not text:
        print(json.dumps({"text": "", "class": "none"}))
        return
    lines.append("")
    lines.append("Click: open daily puzzle · right click: chess menu")
    print(json.dumps({"text": text, "tooltip": "\n".join(lines), "class": "chess"}))


main()
