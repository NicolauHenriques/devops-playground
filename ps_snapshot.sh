#!/usr/bin/env bash
set -euo pipefail

OUTDIR="./logs"
mkdir -p "$OUTDIR"

TS="$(date +%F_%H-%M-%S)"
OUT="$OUTDIR/ps_snapshot_${TS}.txt"

{
  echo "== Process Snapshot @ $(date -Is) =="
  echo "# User: $(whoami)  Host: $(hostname)"
  echo

  echo "## Top 10 processes by CPU"
  ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 11
  echo

  echo "## Top 10 processes by MEM"
  ps -eo pid,comm,%cpu,%mem --sort=-%mem | head -n 11
} >"$OUT"

cat "$OUT"
echo "Saved to: $OUT"

exit 0
