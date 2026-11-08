#!/usr/bin/env python3
"""Weather via Open-Meteo (no key). City: ~/.config/niri/weather.city (default: Vienna). Cached 30 min."""
import json, os, time, urllib.request, urllib.parse
H = os.path.expanduser("~"); CACHE = H + "/.cache/qs-weather.json"
try: city = open(H + "/.config/niri/weather.city").read().strip() or "Vienna"
except OSError: city = "Vienna"
def get(u): return json.load(urllib.request.urlopen(urllib.request.Request(u, headers={"User-Agent": "niri-sidebar"}), timeout=10))
try:
    c = json.load(open(CACHE))
    if c.get("city") == city and time.time() - c["t"] < 1800: print(json.dumps(c["d"])); raise SystemExit
except (OSError, ValueError, KeyError): c = {}
try:
    g = get("https://geocoding-api.open-meteo.com/v1/search?count=1&language=en&name=" + urllib.parse.quote(city))["results"][0]
    w = get(f"https://api.open-meteo.com/v1/forecast?latitude={g['latitude']}&longitude={g['longitude']}&timezone=auto&forecast_days=6"
            "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,precipitation,is_day"
            "&hourly=temperature_2m,weather_code,precipitation_probability"
            "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset")
    cur = w["current"]; now = cur["time"][:13]
    hs = [i for i, t in enumerate(w["hourly"]["time"]) if t[:13] >= now][:10:1]
    d = {"city": g["name"], "temp": round(cur["temperature_2m"]), "feels": round(cur["apparent_temperature"]), "hum": cur["relative_humidity_2m"],
         "wind": round(cur["wind_speed_10m"]), "code": cur["weather_code"], "day": cur["is_day"], "rain": cur["precipitation"],
         "sunrise": w["daily"]["sunrise"][0][11:16], "sunset": w["daily"]["sunset"][0][11:16],
         "hours": [{"t": w["hourly"]["time"][i][11:16], "temp": round(w["hourly"]["temperature_2m"][i]), "code": w["hourly"]["weather_code"][i], "p": w["hourly"]["precipitation_probability"][i]} for i in hs],
         "days": [{"d": w["daily"]["time"][i], "max": round(w["daily"]["temperature_2m_max"][i]), "min": round(w["daily"]["temperature_2m_min"][i]), "code": w["daily"]["weather_code"][i], "p": w["daily"]["precipitation_probability_max"][i]} for i in range(len(w["daily"]["time"]))]}
    json.dump({"city": city, "t": time.time(), "d": d}, open(CACHE, "w")); print(json.dumps(d))
except Exception as e:
    if c.get("d"): print(json.dumps(c["d"]))
    else: print(json.dumps({"error": str(e)[:80]}))
