#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "$ROOT_DIR/config.sh"

OUTDIR="./logs"
mkdir -p "$OUTDIR"

# Optional global config
CONFIG="./config.sh"
if [ -r "$CONFIG" ]; then
  # shellcheck source=/dev/null
  . "$CONFIG"
fi

# Threshold precedence:
#   1) WARN_MEM / CRIT_MEM env vars (strongest)
#   2) HEALTH_WARN_MEM / HEALTH_CRIT_MEM from config.sh
#   3) Hard-coded defaults 800 / 300
WARN_MEM="${WARN_MEM:-${HEALTH_WARN_MEM:-800}}"
CRIT_MEM="${CRIT_MEM:-${HEALTH_CRIT_MEM:-300}}"

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
