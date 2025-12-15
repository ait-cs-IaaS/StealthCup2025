#!/usr/bin/env python3
# first in duckdb ".read first_kali_interaction.sql"
from pathlib import Path
import yaml

IN = Path("dataset_run_index.yaml")
data = yaml.safe_load(IN.read_text(encoding="utf-8"))
runs = data.get("runs", [])

def team_num(team_id: str) -> int:
    return int(str(team_id).replace("team", ""))

def run_num(run_id: str) -> int:
    return int(str(run_id).replace("run", ""))

def norm_ts(ts):
    if ts in (None, "None", ""):
        return None
    # accept either "YYYY-MM-DD HH:MM:SS" or ISO with T
    return str(ts).replace("T", " ")

# sort: team1/run1, team1/run2, ...
runs.sort(key=lambda r: (team_num(r["team_id"]), run_num(r["run_id"])))

out = []
for r in runs:
    team_id = r["team_id"]
    run_id  = r["run_id"]
    tnum    = team_num(team_id)

    tl = r.get("timeline", {}) or {}
    suri = norm_ts(tl.get("suricata_start"))

    if not suri:
        out.append(f"-- {team_id} {run_id}: SKIPPED (no timeline.suricata_start)")
        continue

    out.append(f"-- {team_id} {run_id} (after timeline.suricata_start={suri})")
    out.append(f"SELECT * FROM first_kali_interaction({tnum}, TIMESTAMP '{suri}');")
    out.append("")

print("\n".join(out).strip())