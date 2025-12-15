#!/usr/bin/env bash
set -euo pipefail

OUT="dataset_run_index.yaml"
GEN_AT="$(date "+%Y-%m-%dT%H:%M:%S")"

RUNFILES="$(find . -type f -name run.yaml -path './team*/run*/run.yaml' | sort)"
RUNCOUNT="$(printf "%s\n" "$RUNFILES" | sed '/^$/d' | wc -l | tr -d ' ')"

get_key() {
  # args: key file
  awk -v k="$1" '
    $1==k":" {
      sub(/^([^:]+):[ ]*/, "", $0)
      print $0
      exit
    }
  ' "$2"
}

get_timeline_key() {
  # args: key file
  awk -v k="$1" '
    $1=="timeline:" {flag=1; next}
    flag && $1==k":" {
      sub(/^[ ]+[^:]+:[ ]*/, "", $0)
      print $0
      exit
    }
    flag && $0 !~ /^[ ]+/ {exit}
  ' "$2"
}

q() {
  # quote strings, keep None/empty as None
  case "${1:-}" in
    None|"") echo "None" ;;
    \"*\"|\'*\' ) echo "$1" ;;
    * ) echo "\"$1\"" ;;
  esac
}

{
  echo "dataset:"
  echo "  name: stealthcup"
  echo "  generated_at: \"$GEN_AT\""
  echo "  run_count: $RUNCOUNT"
  echo ""
  echo "runs:"
} > "$OUT"

while IFS= read -r f; do
  [ -f "$f" ] || continue

  team_id="$(get_key team_id "$f")"
  run_id="$(get_key run_id "$f")"
  team_subnet="$(get_key team_subnet "$f")"

  start="$(get_timeline_key start "$f")"
  suri="$(get_timeline_key suricata_start "$f")"
  it="$(get_timeline_key it_flag "$f")"
  ot="$(get_timeline_key ot_flag "$f")"
  reset="$(get_timeline_key reset "$f")"
  writeup="$(get_timeline_key writeup "$f")"
  host_logs="$(get_timeline_key host_logs "$f")"

  {
    echo "  - team_id: $(q "$team_id")"
    echo "    run_id: $(q "$run_id")"
    echo "    team_subnet: $(q "$team_subnet")"
    echo "    path: \"${f#./}\""
    echo "    timeline:"
    echo "      start: $(q "$start")"
    echo "      suricata_start: $(q "$suri")"
    echo "      it_flag: $(q "$it")"
    echo "      ot_flag: $(q "$ot")"
    echo "      reset: $(q "$reset")"
    echo "      writeup: $(q "$writeup")"
    echo "      host_logs: $(q "$host_logs")"
  } >> "$OUT"

done <<< "$RUNFILES"

echo "Wrote: $OUT"
