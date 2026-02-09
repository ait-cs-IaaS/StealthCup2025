import pandas as pd
from sklearn.metrics import cohen_kappa_score

FILE = "ManualDetectionEvaluation_Felix.xlsx"

COL_DOM = "Attack Confidence Pentester A"
COL_FEL = "Attack Confidence Pentester B"

# ── Read all sheets ──────────────────────────────────────────────────────────
xls = pd.ExcelFile(FILE)
all_rows = []
skipped_sheets = []
empty_sheets = []

print("=" * 70)
print("DEBUG: Sheet-by-sheet processing")
print("=" * 70)

for sheet in xls.sheet_names:
    df = pd.read_excel(FILE, sheet_name=sheet)

    # Check if both rater columns exist
    if COL_DOM not in df.columns or COL_FEL not in df.columns:
        skipped_sheets.append((sheet, "missing column(s)"))
        print(f"  SKIP  {sheet:45s}  reason: missing rater column(s)")
        continue

    sub = df[[COL_DOM, COL_FEL]].copy()
    sub["__sheet__"] = sheet

    rows_before_dropna = len(sub)

    # Drop rows where either rater value is missing
    sub = sub.dropna(subset=[COL_DOM, COL_FEL])
    rows_after_dropna = len(sub)

    # Coerce to numeric (handles strings like "3.0")
    sub[COL_DOM] = pd.to_numeric(sub[COL_DOM], errors="coerce")
    sub[COL_FEL] = pd.to_numeric(sub[COL_FEL], errors="coerce")
    sub = sub.dropna(subset=[COL_DOM, COL_FEL])
    rows_after_numeric = len(sub)

    # Convert to int (discrete 1-5 scale)
    sub[COL_DOM] = sub[COL_DOM].astype(int)
    sub[COL_FEL] = sub[COL_FEL].astype(int)

    dropped_na = rows_before_dropna - rows_after_dropna
    dropped_nonnumeric = rows_after_dropna - rows_after_numeric

    if len(sub) == 0:
        empty_sheets.append(sheet)
        print(f"  EMPTY {sheet:45s}  raw={rows_before_dropna}  "
              f"dropped(na={dropped_na}, non-numeric={dropped_nonnumeric})  usable=0")
        continue

    # Debug: value distribution per sheet
    print(f"  OK    {sheet:45s}  raw={rows_before_dropna}  "
          f"dropped(na={dropped_na}, non-numeric={dropped_nonnumeric})  usable={len(sub)}")
    print(f"        Dominik values: {dict(sub[COL_DOM].value_counts().sort_index())}")
    print(f"        Felix   values: {dict(sub[COL_FEL].value_counts().sort_index())}")

    all_rows.append(sub)

# ── Summary of sheet inclusion ───────────────────────────────────────────────
print("\n" + "=" * 70)
print("DEBUG: Sheet inclusion summary")
print("=" * 70)
print(f"  Total sheets in file:     {len(xls.sheet_names)}")
print(f"  Sheets with both columns: {len(xls.sheet_names) - len(skipped_sheets)}")
print(f"  Sheets skipped (missing): {len(skipped_sheets)}")
for s, reason in skipped_sheets:
    print(f"    - {s}: {reason}")
print(f"  Sheets with 0 usable rows:{len(empty_sheets)}")
for s in empty_sheets:
    print(f"    - {s}")
print(f"  Sheets contributing data: {len(all_rows)}")

if not all_rows:
    raise ValueError(f"No sheets found containing both '{COL_DOM}' and '{COL_FEL}' with usable data")

# ── Pool all data ────────────────────────────────────────────────────────────
pooled = pd.concat(all_rows, ignore_index=True)

# ── Debug: pooled value distributions ────────────────────────────────────────
print("\n" + "=" * 70)
print("DEBUG: Pooled data summary")
print("=" * 70)
print(f"  Total pooled rows: {len(pooled)}")
print(f"\n  Dominik label distribution:")
for val, cnt in sorted(pooled[COL_DOM].value_counts().items()):
    print(f"    label {val}: {cnt:>6d}  ({100*cnt/len(pooled):.1f}%)")
print(f"\n  Felix label distribution:")
for val, cnt in sorted(pooled[COL_FEL].value_counts().items()):
    print(f"    label {val}: {cnt:>6d}  ({100*cnt/len(pooled):.1f}%)")

# ══════════════════════════════════════════════════════════════════════════════
# VERSION 2: Binary FP-based kappa
#   FP  = labels 1, 2  (false positive / benign)      [< 3]
#   TP  = labels 3, 4, 5  (true positive / attack-related)  [>= 3]
# ══════════════════════════════════════════════════════════════════════════════

print("\n")
print("#" * 70)
print("#  VERSION 2: Binary False-Positive Kappa")
print("#  FP  = Attack Confidence < 3  (1, 2)  (false positive)")
print("#  TP  = Attack Confidence >= 3  (3, 4, 5)  (true positive / attack)")
print("#" * 70)

def to_fp_label(val):
    """Map confidence < 3 → 'FP', >= 3 → 'TP'."""
    return "FP" if val < 3 else "TP"

pooled["FP_Dominik"] = pooled[COL_DOM].apply(to_fp_label)
pooled["FP_Felix"]   = pooled[COL_FEL].apply(to_fp_label)

# ── Debug: binary label distributions ────────────────────────────────────────
print("\n" + "=" * 70)
print("DEBUG: Binary label distributions (pooled)")
print("=" * 70)

print(f"\n  Dominik:  original → binary mapping")
for val in sorted(pooled[COL_DOM].unique()):
    cnt = (pooled[COL_DOM] == val).sum()
    print(f"    label {val} → {to_fp_label(val):2s}  ({cnt:>6d} rows)")

dom_fp = (pooled["FP_Dominik"] == "FP").sum()
dom_tp = (pooled["FP_Dominik"] == "TP").sum()
print(f"    ──────────────────────────────")
print(f"    FP total: {dom_fp:>6d}  ({100*dom_fp/len(pooled):.1f}%)")
print(f"    TP total: {dom_tp:>6d}  ({100*dom_tp/len(pooled):.1f}%)")

print(f"\n  Felix:  original → binary mapping")
for val in sorted(pooled[COL_FEL].unique()):
    cnt = (pooled[COL_FEL] == val).sum()
    print(f"    label {val} → {to_fp_label(val):2s}  ({cnt:>6d} rows)")

fel_fp = (pooled["FP_Felix"] == "FP").sum()
fel_tp = (pooled["FP_Felix"] == "TP").sum()
print(f"    ──────────────────────────────")
print(f"    FP total: {fel_fp:>6d}  ({100*fel_fp/len(pooled):.1f}%)")
print(f"    TP total: {fel_tp:>6d}  ({100*fel_tp/len(pooled):.1f}%)")

# ── Binary confusion matrix ─────────────────────────────────────────────────
print(f"\n  Binary agreement matrix (rows=Dominik, cols=Felix):")
bin_conf = pd.crosstab(pooled["FP_Dominik"], pooled["FP_Felix"],
                       margins=True, margins_name="Total")
print(bin_conf.to_string().replace("\n", "\n  "))

# Exact binary agreement
bin_agree = (pooled["FP_Dominik"] == pooled["FP_Felix"]).sum()
print(f"\n  Binary exact agreement: {bin_agree}/{len(pooled)} = {100*bin_agree/len(pooled):.1f}%")

# ── FP rates per rater ──────────────────────────────────────────────────────
print(f"\n  FP rates:")
print(f"    Dominik: {dom_fp}/{len(pooled)} = {100*dom_fp/len(pooled):.2f}%")
print(f"    Felix:   {fel_fp}/{len(pooled)} = {100*fel_fp/len(pooled):.2f}%")

# ── Binary Cohen's kappa ────────────────────────────────────────────────────
kappa_binary = cohen_kappa_score(pooled["FP_Dominik"], pooled["FP_Felix"])

print("\n" + "=" * 70)
print("RESULTS: Binary FP Kappa")
print("=" * 70)
print(f"  Pooled rows:                        {len(pooled)}")
print(f"  Cohen's kappa (binary FP/TP):        {kappa_binary:.4f}")

# ── Per-sheet binary kappa ───────────────────────────────────────────────────
per_sheet_bin = []
for sheet in pooled["__sheet__"].unique():
    s = pooled[pooled["__sheet__"] == sheet]
    n = len(s)
    fp_dom = (s["FP_Dominik"] == "FP").sum()
    fp_fel = (s["FP_Felix"] == "FP").sum()
    fp_rate_dom = fp_dom / n if n > 0 else float("nan")
    fp_rate_fel = fp_fel / n if n > 0 else float("nan")

    if n >= 2:
        dom_u = s["FP_Dominik"].nunique()
        fel_u = s["FP_Felix"].nunique()
        if dom_u == 1 and fel_u == 1:
            k_bin = 1.0 if s["FP_Dominik"].iloc[0] == s["FP_Felix"].iloc[0] else 0.0
            note = " (constant)"
        else:
            k_bin = cohen_kappa_score(s["FP_Dominik"], s["FP_Felix"])
            note = ""
    else:
        k_bin = float("nan")
        note = " (too few rows)"

    per_sheet_bin.append((sheet, n, fp_rate_dom, fp_rate_fel, k_bin, note))

print("\n" + "=" * 70)
print("Per-sheet binary FP kappas (largest sheets first)")
print("=" * 70)
out_bin = pd.DataFrame(per_sheet_bin,
                       columns=["sheet", "n_rows", "FP_rate_Dom", "FP_rate_Fel",
                                "kappa_binary", "note"])
out_bin = out_bin.sort_values("n_rows", ascending=False)
# Format FP rates as percentages for display
out_bin["FP_rate_Dom"] = out_bin["FP_rate_Dom"].apply(lambda x: f"{100*x:.1f}%")
out_bin["FP_rate_Fel"] = out_bin["FP_rate_Fel"].apply(lambda x: f"{100*x:.1f}%")
print(out_bin.to_string(index=False))

# ══════════════════════════════════════════════════════════════════════════════
# VERSION 3: Per team+run kappas (objIT/objOT/normal merged)
#   Sheet names like df_wz_result_team6_run1_objIT / _objOT / _normal
#   are grouped into df_wz_result_team6_run1
# ══════════════════════════════════════════════════════════════════════════════

import re

def sheet_to_group(sheet_name):
    """Strip _objIT, _objOT, _normal suffixes to get IDS+team+run group key."""
    return re.sub(r'_(objIT|objOT|normal)$', '', sheet_name)

pooled["__group__"] = pooled["__sheet__"].apply(sheet_to_group)

print("\n\n")
print("#" * 70)
print("#  VERSION 3: Per team+run kappas (objIT/objOT/normal merged)")
print("#" * 70)

# Debug: show which sheets map to which group
print("\n" + "=" * 70)
print("DEBUG: Sheet → group mapping")
print("=" * 70)
for grp in sorted(pooled["__group__"].unique()):
    sheets_in_grp = sorted(pooled[pooled["__group__"] == grp]["__sheet__"].unique())
    print(f"  {grp}")
    for s in sheets_in_grp:
        n = len(pooled[pooled["__sheet__"] == s])
        print(f"    ← {s} ({n} rows)")

# ── Binary FP kappa per group ────────────────────────────────────────────────
print("\n" + "=" * 70)
print("Per team+run binary FP kappas (largest groups first)")
print("=" * 70)

per_group_bin = []
for grp in pooled["__group__"].unique():
    g = pooled[pooled["__group__"] == grp]
    n = len(g)
    fp_dom = (g["FP_Dominik"] == "FP").sum()
    fp_fel = (g["FP_Felix"] == "FP").sum()
    fp_rate_dom = fp_dom / n if n > 0 else float("nan")
    fp_rate_fel = fp_fel / n if n > 0 else float("nan")

    if n >= 2:
        dom_u = g["FP_Dominik"].nunique()
        fel_u = g["FP_Felix"].nunique()
        if dom_u == 1 and fel_u == 1:
            k_bin = 1.0 if g["FP_Dominik"].iloc[0] == g["FP_Felix"].iloc[0] else 0.0
            note = " (constant)"
        else:
            k_bin = cohen_kappa_score(g["FP_Dominik"], g["FP_Felix"])
            note = ""
    else:
        k_bin = float("nan")
        note = " (too few rows)"

    per_group_bin.append((grp, n, fp_rate_dom, fp_rate_fel, k_bin, note))

out_grp_bin = pd.DataFrame(per_group_bin,
                           columns=["group", "n_rows", "FP_rate_Dom", "FP_rate_Fel",
                                    "kappa_binary", "note"])
out_grp_bin = out_grp_bin.sort_values("n_rows", ascending=False)
out_grp_bin["FP_rate_Dom"] = out_grp_bin["FP_rate_Dom"].apply(lambda x: f"{100*x:.1f}%")
out_grp_bin["FP_rate_Fel"] = out_grp_bin["FP_rate_Fel"].apply(lambda x: f"{100*x:.1f}%")
print(out_grp_bin.to_string(index=False))
