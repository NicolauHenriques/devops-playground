#!/usr/bin/env bash
set -euo pipefail

OUTDIR="./logs"
mkdir -p "$OUTDIR"

TS="$(date +%F_%H-%M-%S)"
OUT="$OUTDIR/health_overall_${TS}.txt"

# Start a fresh report file
{

  echo "== Overall Health @ $(date -Is) =="
  echo
} >"$OUT"

# Run disk check
{
  echo "## Disk"
  ./health_disk.sh
  disk_status=$?
  echo "disk_status=${disk_status}"
  echo
} >>"$OUT"

# Run memory check
{
  echo "## Memory"
  ./health_mem.sh
  mem_status=$?
  echo "mem_status=${mem_status}"
  echo
} >>"$OUT"

# Decide overall status = worst of disk_status and mem_status
overall=$disk_status
if [ "$mem_status" -gt "$overall" ]; then
  overall=$mem_status
fi

{
  echo "Summary:"
  case "$overall" in
    0) echo "OVERALL: OK" ;;
    1) echo "OVERALL: WARNING" ;;
    2) echo "OVERALL: CRITICAL" ;;
    3) echo "OVERALL: UNKNOWN (${overall})" ;;
  esac
} >>"$OUT"

# Show the report and the exit with the overall status
cat "$OUT"
echo "Saved to: $OUT"
exit "$overall"
