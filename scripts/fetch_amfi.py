import requests, json

URL = "https://www.amfiindia.com/spages/NAVAll.txt"

res = requests.get(URL, timeout=30)
lines = res.text.splitlines()

hist = scheme_code.history(period="10y")

data = {}
for line in lines:
    if line.count(";") >= 4 and line[0].isdigit():
        parts = line.split(";")
        scheme_code = parts[0]
        nav = parts[4]
        date = parts[5]
        data.setdefault(scheme_code, []).append({
            "date": date,
            "nav": float(nav)
        })

with open("amfi_nav_cache.json", "w") as f:
    json.dump(data, f)
