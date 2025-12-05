#!/usr/bin/env bash
set -euo pipefail

OUTDIR="./logs"
mkdir -p "$OUTDIR"

# Allow env overrides: WARN_MEM=1000 CRIT_MEM=500 ./health_mem.sh
WARN_MEM="${WARN_MEM:-800}" # warn if free < 800 MB
CRIT_MEM="${CRIT_MEM:-300}" # critical if free < 300 MB

TS="$(date +%F_%H-%M-%S)"
OUT="$OUTDIR/health_mem_${TS}.txt"

STATUS=0

check_mem() {
  # Use the "available" coluimn from free -m (7th column)
  local mem_free
  mem_free="$(free -m | awk 'NR==2 {print $7}')"

  echo "mem_free_mb=${mem_free} WARN_MEM=${WARN_MEM} CRIT_MEM=${CRIT_MEM}"

  if [ "$mem_free" -lt "$CRIT_MEM" ]; then
    echo "CRITICAL: free memory ${mem_free}MB (< ${CRIT_MEM}MB)"
    STATUS=2
  elif [ "$mem_free" -lt  "$WARN_MEM" ]; then
    echo "WARNING: free memory ${mem_free}MB (< ${WARN_MEM}MB)"
    if [ "$STATUS" -lt 1 ]; then
      STATUS=1
    fi
  else
    echo "OK: free memory ${mem_free}MB"
  fi
}


# Build the report into the file (no pipeline here, so STATUS survives)
{
  echo "== Memory Health @ $(date -Is) =="
  check_mem
  echo
  echo "Summary:"
  case "$STATUS" in
    0) echo "OVERALL: OK" ;;
    1) echo "OVERALL: WARNING" ;;
    2) echo "OVERALL: CRITICAL" ;;
  esac
} > "$OUT"


# Show the report and exit with the correct code
cat "$OUT"
echo "Saved to: $OUT"
exit "$STATUS"
