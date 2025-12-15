#!/usr/bin/env python3
import yaml
import pandas as pd
from tabulate import tabulate
from pathlib import Path

IN = Path("dataset_run_index.yaml")
OUT = Path("dataset_run_index.md")

data = yaml.safe_load(IN.read_text(encoding="utf-8"))

def s(x):
    # Make missing values visually distinct in GitHub markdown tables
    if x == "None" or x == "":
        return "`None`"
    return str(x)

rows = []
for r in data.get("runs", []):
    tl = r.get("timeline", {}) or {}

    raw = {
        "Team": r.get("team_id"),
        "Run": r.get("run_id"),
        "Subnet": r.get("team_subnet"),
        "Start": tl.get("start"),
        "Suricata start": tl.get("suricata_start"),
        "Host logs": tl.get("host_logs"),
        "Writeup": tl.get("writeup"),
        "IT flag": tl.get("it_flag"),
        "OT flag": tl.get("ot_flag"),
        "Reset": tl.get("reset"),
    }

    rows.append({k: s(v) for k, v in raw.items()})

df = pd.DataFrame(rows)

# Sort nicely: team1, team2, … / run1, run2, …
def team_num(x):
    try:
        return int(str(x).replace("team", "").replace("`None`", "999"))
    except:
        return 999

def run_num(x):
    try:
        return int(str(x).replace("run", "").replace("`None`", "999"))
    except:
        return 999

df["t"] = df["Team"].map(team_num)
df["r"] = df["Run"].map(run_num)
df = df.sort_values(["t", "r"]).drop(columns=["t", "r"])

md = tabulate(df, headers="keys", tablefmt="github", showindex=False)

OUT.write_text(md + "\n", encoding="utf-8")
print(f"Wrote {OUT.name}")