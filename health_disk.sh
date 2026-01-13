#!/usr/bin/env bash
set -euo pipefail

# Optional global config
CONFIG="./config.sh"
if [ -r "$CONFIG" ]; then
  # shellcheck source=/dev/null  # harmless marker for later if you ever use shellcheck
  . "$CONFIG"
fi

OUTDIR="./logs"
mkdir -p "$OUTDIR"

# Allow env overrides: WARN=70 CRIT=90 ./health_disk.sh
# Precedence:
#   1) WARN / CRIT environment variables (strongest)
#   2) HEALTH_WARN_DISK / HEALTH_CRIT_DISK from config.sh (if set)
#   3) Hard-coded defaults 85/95
WARN="${WARN:-${HEALTH_WARN_DISK:-85}}" # warning threshold for disk /
CRIT="${CRIT:-${HEALTH_CRIT_DISK:-95}}" # critical threshold for disk /

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
    exit 2
  elif [ "$DISK_USE" -ge "$WARN" ]; then
    echo "WARNING: / is at or above ${WARN}%"
    exit 1
  else
    echo "OK: / usage is below ${WARN}%"
    exit 0
  fi
} | tee "$OUT"

STATUS=$?
echo "Saved to: $OUT"
exit "$STATUS"
