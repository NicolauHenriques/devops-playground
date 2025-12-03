#!/usr/bin/env bash
set -euo pipefail

OUTDIR="./logs"
mkdir -p "$OUTDIR"

# Allow env overrides: WARN=70 CRIT=90 ./health_disk.sh
WARN="${WARN:-85}"   # warning threshold for disk /
CRIT="${CRIT:-95}"   # critical threshold for disk /

TS="$(date +%F_%H-%M-%S)"
OUT="$OUTDIR/health_disk_${TS}.txt"

# Get disk usage percentage (number only) for /
DISK_USE="$(df -P / | awk 'NR==2 {gsub(/%/,"",$5); print $5}')"
STATUS=0

{
  echo "== Disk Health @ $(date -Is) =="
  echo "disk_use_pct=$DISK_USE WARN=$WARN CRIT=$CRIT"

  if [ "$DISK_USE" -ge "$CRIT" ]; then
    echo "CRITICAL: / is at or above ${CRIT}%"
    STATUS=2
  elif [ "$DISK_USE" -ge "$WARN" ]; then
    echo "WARNING: / is at or above ${WARN}%"
    STATUS=1
  else
    echo "OK: / usage is below ${WARN}%"
    STATUS=0
  fi
} | tee "$OUT"

echo "Saved to: $OUT"
exit "$STATUS"
